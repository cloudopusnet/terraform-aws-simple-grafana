#!/bin/bash
set -euxo pipefail
aws s3 sync /var/lib/grafana/plugins/ s3://${backup_bucket_name}/plugins/
aws s3 cp /var/lib/grafana/grafana.db  s3://${backup_bucket_name}/db/grafana.db
