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
worker_processes auto;
pid /run/nginx.pid;

map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}

upstream grafana {
  server localhost:3000;
}

events {
  worker_connections 1024;
}

http {
  server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    return 301 https://$host$request_uri;
  }

  server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate /etc/ssl/grafana.crt;
    ssl_certificate_key /etc/ssl/grafana.key;

    location / {
      proxy_set_header Host $host;
      proxy_pass http://grafana;
    }

    location /api/live/ {
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_set_header Host $host;
      proxy_pass http://grafana;
    }
  }
}
NGINX_CONFIG

# Restart Nginx to apply changes
systemctl restart nginx
systemctl enable nginx
