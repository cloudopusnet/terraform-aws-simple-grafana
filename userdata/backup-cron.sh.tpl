#!/bin/bash
set -euxo pipefail
# shellcheck disable=SC2154,SC2086
aws s3 sync /var/lib/grafana/plugins/ s3://${backup_bucket_name}/plugins/
# shellcheck disable=SC2154,SC2086
aws s3 cp /var/lib/grafana/grafana.db  s3://${backup_bucket_name}/db/grafana.db
