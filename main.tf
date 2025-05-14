locals {
  name_prefix                   = "grafana"
  instance_security_groups      = concat(var.security_group_ids, [aws_security_group.main.id])
  ssm_managed_instance_core_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  user_data = base64encode(join("\n", [
    templatefile("${path.module}/ec2-grafana-userdata.sh.tpl", {
      backup_bucket_name = var.backup_bucket_name
    }),
    templatefile("${path.module}/ec2-nginx-userdata.sh.tpl", {
      nginx_ssl_cert_parameter_name     = var.nginx_ssl_cert_parameter_name
      nginx_ssl_cert_key_parameter_name = var.nginx_ssl_cert_key_parameter_name
    }),
    templatefile("${path.module}/ec2-backup-sync.sh.tpl", {
      backup_bucket_name = var.backup_bucket_name
    })
    ])
  )
}

##########
## Security Group
##########
resource "aws_security_group" "main" {
  name        = local.name_prefix
  description = "${local.name_prefix} Security Group for the terraform-aws-simple-grafana stack"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "main_ingress_http" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  description       = "Allow incoming http traffic"
}

resource "aws_security_group_rule" "main_ingress_https" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  description       = "Allow incoming https traffic"
}

resource "aws_security_group_rule" "main_egress_all" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.main.id
  type              = "egress"
  description       = "Allow all outgoing traffic"
}

##########
## Elastic IP
##########
resource "aws_network_interface" "main" {
  subnet_id       = var.instance_subnet_id
  security_groups = local.instance_security_groups
  tags = {
    Name = local.name_prefix
  }
}

resource "aws_eip" "main" {
  domain            = "vpc"
  network_interface = aws_network_interface.main.id
  tags = {
    Name = local.name_prefix
  }
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
  name               = local.name_prefix
  description        = "${local.name_prefix} Instance Profile IAM Role for the terraform-aws-simple-grafana stack"
}

resource "aws_iam_role_policy_attachment" "profile_ssm" {
  role       = aws_iam_role.profile.id
  policy_arn = local.ssm_managed_instance_core_arn
}

resource "aws_iam_instance_profile" "main" {
  role = aws_iam_role.profile.id
  name = local.name_prefix
}

##########
## Launch Template
##########
resource "aws_launch_template" "main" {
  name                   = local.name_prefix
  description            = "${local.name_prefix} Launch Tempplate for the terraform-aws-simple-grafana stack"
  image_id               = "ami-0cd3f0d8daa83abeb"
  user_data              = local.user_data
  instance_type          = var.instance_type
  update_default_version = true
  ebs_optimized          = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"

  }
  network_interfaces {
    network_interface_id = aws_network_interface.main.id
  }
  instance_market_options {
    market_type = "spot"
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = var.block_device_mappings.volume_type
      throughput  = var.block_device_mappings.throughput
      iops        = var.block_device_mappings.iops
      encrypted   = var.block_device_mappings.encrypted
      volume_size = var.block_device_mappings.volume_size
    }
  }
}

##########
## EC2 Instance
##########
resource "aws_instance" "main" {
  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }
  tags = {
    Name = local.name_prefix
  }
}
