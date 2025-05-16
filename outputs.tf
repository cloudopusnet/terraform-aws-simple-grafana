output "grafana_instance_public_ip" {
  value       = aws_eip.main.public_ip
  description = "Public IP Address of the Grafana Instance"
}
