variable "vpc_id" {
  type        = string
  description = "The VPC Id where the simple-grafana stack will be launched"
  nullable    = false
}

variable "instance_subnet_id" {
  type        = string
  description = "The Subnet Id where the simple grafana stack will be launched"
  nullable    = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security Group Ids attached to the Grafana Instance"
  default     = []
}

variable "instance_type" {
  type        = string
  description = "Instance Type of the Grafana Instance"
  default     = "t4g.small"
}

variable "block_device_mappings" {
  type = object({
    volume_type = string
    volume_size = number
    encrypted   = bool
    iops        = number
    throughput  = number
  })
  description = "Attached EBS Root volume properties"
  default = {
    volume_type = "gp3"
    volume_size = 20
    iops        = 3000
    throughput  = 125
    encrypted   = true
  }
}

variable "nginx_ssl_cert_parameter_name" {
  type        = string
  description = "Name of the SSL parameter of the TLS Certification for NGINX reverse proxy"
  nullable    = false
}

variable "nginx_ssl_cert_key_parameter_name" {
  type        = string
  description = "Name of the SSL parameter of TLS Certification Key for NGINX reverse proxy"
  nullable    = false
}

variable "backup_bucket_name" {
  type        = string
  description = "Name of the Backup Bucket"
  nullable    = false
}

variable "grafana_config_ini" {
  type = object({
    paths = object({
      data               = optional(string, "/var/lib/grafana")
      temp_data_lifetime = optional(string, "18h")
      logs               = optional(string, "/var/lib/grafana/plugins")
      plugins            = optional(string, "/var/log/grafana")
    })
  })
}
