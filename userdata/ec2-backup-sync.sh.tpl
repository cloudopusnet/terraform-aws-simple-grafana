#!/bin/bash
set -euxo pipefail

# Install cronie
dnf install cronie -y

# Create the Grafana Backup Cron
cat > /usr/local/sbin/grafana-backup-cron.sh << 'GRAFANA_CRON'
${backup_sync_content}
GRAFANA_CRON

chmod +x /usr/local/sbin/grafana-backup-cron.sh

# Define paths
CRON_FILE="/etc/cron.d/backup"
SCRIPT_PATH="/usr/local/sbin/grafana-backup-cron.sh"

# Ensure the script is executable
chmod +x "$SCRIPT_PATH"

# Create the cron job file
cat <<CRONTAB | tee "$CRON_FILE" > /dev/null
*/10 * * * * root $SCRIPT_PATH
CRONTAB

# Set correct permissions
chown root:root "$CRON_FILE"
chmod 644 "$CRON_FILE"

# Enable crond
systemctl enable --now crond
