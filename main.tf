locals {
  name_prefix                   = "Grafana"
  instance_security_groups      = concat(var.security_group_ids, [aws_security_group.main.id])
  ssm_managed_instance_core_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  user_data = base64encode(templatefile("${path.module}/ec2-userdata.sh.tpl", {

  }))
}

##########
## Security Group
##########
resource "aws_security_group" "main" {
  name   = "sgtest"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "main_ingress_http" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.main.id
  type              = "ingress"
}

resource "aws_security_group_rule" "main_ingress_https" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.main.id
  type              = "ingress"
}

resource "aws_security_group_rule" "main_egress_all" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.main.id
  type              = "egress"
}

##########
## Elastic IP
##########
resource "aws_network_interface" "main" {
  subnet_id       = var.instance_subnet_id
  security_groups = local.instance_security_groups
}

resource "aws_eip" "main" {
  domain            = "vpc"
  network_interface = aws_network_interface.main.id
}

resource "aws_eip_association" "main" {
  allocation_id        = aws_eip.main.id
  network_interface_id = aws_network_interface.main.id
}

##########
## Instance Profile
##########
data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "profile" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "${local.name_prefix}Profile"
}

resource "aws_iam_role_policy_attachment" "profile_ssm" {
  role       = aws_iam_role.profile.id
  policy_arn = local.ssm_managed_instance_core_arn
}

resource "aws_iam_instance_profile" "main" {
  role = aws_iam_role.profile.id
  name = "${local.name_prefix}Profile"
}


##########
## Launch Template
##########
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
}

resource "aws_launch_template" "main" {
  name      = "test"
  image_id  = "ami-0ce1f41dd519a3b4c"
  user_data = local.user_data
  network_interfaces {
    network_interface_id = aws_network_interface.main.id
  }
  instance_type = "t4g.small"

  update_default_version = true

  instance_market_options {
    market_type = "spot"
  }

  ebs_optimized = true
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = "gp3"
      throughput  = 125
      iops        = 3000
      encrypted   = true
      volume_size = 8
    }
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }
}

resource "aws_instance" "main" {
  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }
}