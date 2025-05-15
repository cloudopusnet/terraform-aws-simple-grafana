#!/bin/bash
set -euxo pipefail

dnf install nginx -y

# Fetch SSL certificate and key from Parameter Store
CERT_PATH="/etc/ssl/grafana.crt"
KEY_PATH="/etc/ssl/grafana.key"

aws ssm get-parameter --name "${nginx_ssl_cert_parameter_name}" --with-decryption \
  --query "Parameter.Value" --output text > "$CERT_PATH"

aws ssm get-parameter --name "${nginx_ssl_cert_key_parameter_name}" --with-decryption \
  --query "Parameter.Value" --output text > "$KEY_PATH"

# Set appropriate permissions
chmod 600 "$KEY_PATH"
chmod 644 "$CERT_PATH"

# Overwrite Nginx config with HTTPS and redirect
cat > /etc/nginx/nginx.conf << 'NGINX_CONFIG'
${nginx_config_content}
NGINX_CONFIG

# Restart Nginx to apply changes
systemctl restart nginx
systemctl enable nginx
