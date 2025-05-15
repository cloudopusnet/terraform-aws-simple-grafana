#!/bin/bash
set -euxo pipefail

# Import GPG Key
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
rpm --import gpg.key

# Create the Grafana Repo
cat > /etc/yum.repos.d/grafana.repo << 'GRAFANA_REPO'
${grafana_repo_content}
GRAFANA_REPO

# Install Grafana
dnf install grafana -y

# Start Grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

# Restore from Backup
aws s3 sync s3://${backup_bucket_name}/plugins/ /var/lib/grafana/plugins/ || echo "failed"
aws s3 cp s3://${backup_bucket_name}/db/grafana.db /var/lib/grafana/grafana.db || echo "failed"

chown -R grafana.grafana /var/lib/grafana/plugins/
systemctl restart grafana-server
