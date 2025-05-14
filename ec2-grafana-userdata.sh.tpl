#!/bin/bash
set -euxo pipefail

# Import GPG Key
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
rpm --import gpg.key

# Create the Grafana Repo
cat > /etc/yum.repos.d/grafana.repo << 'GRAFANA_REPO'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
GRAFANA_REPO

# Install Grafana
dnf install grafana -y

# Start Grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service
