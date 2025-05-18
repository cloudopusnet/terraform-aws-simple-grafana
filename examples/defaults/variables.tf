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
