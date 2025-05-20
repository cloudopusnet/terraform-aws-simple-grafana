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

cat > /etc/grafana/grafana.ini << 'GRAFANA_INI'
${grafana_config_ini_content}
GRAFANA_INI

# Start Grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

# Restore from Backup
# shellcheck disable=SC2154
aws s3 sync s3://${backup_bucket_name}/plugins/ ${path_plugins}/ || echo "failed"
# shellcheck disable=SC2154
aws s3 cp s3://${backup_bucket_name}/db/grafana.db ${path_data}/grafana.db || echo "failed"

chown -R grafana.grafana ${path_plugins}/
systemctl restart grafana-server
