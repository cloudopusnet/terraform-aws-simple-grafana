module "vpc" {
  source = "cloudopusnet/simple-ipv4-vpc/aws"
}

module "s3" {
  source             = "cloudopusnet/simple-s3-bucket/aws"
  force_destroy      = true
  versioning_enabled = true
}

module "grafana" {
  source = "../../aws/terraform-aws-simple-grafana"

  vpc_id                            = module.vpc.vpc_id
  instance_subnet_id                = module.vpc.public_subnet_ids[0]
  backup_bucket_name                = module.s3.bucket_name
  nginx_ssl_cert_key_parameter_name = "<reference to the nginx ssl certificate key file>"
  nginx_ssl_cert_parameter_name     = "<reference to the nginx ssl certificate crt file>"
}

output "grafana_instance_public_ip" {
  value = module.grafana.grafana_instance_public_ip
}
