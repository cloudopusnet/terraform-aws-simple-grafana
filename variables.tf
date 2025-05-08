variable "vpc_id" {
  type     = string
  nullable = false
}

variable "instance_subnet_id" {
  type     = string
  nullable = false
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}
