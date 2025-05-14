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
