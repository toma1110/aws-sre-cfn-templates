#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

LOG_GROUP="${LOG_GROUP:-/aws/ec2/sre-handson/webapp}"
QUERY="${QUERY:-fields @timestamp, level, message, requestId, path, status, duration | filter status >= 500 or level = \"ERROR\" | sort @timestamp desc | limit 20}"
START_TIME="$(date -u -d '1 hour ago' +%s 2>/dev/null || python - <<'PY'
import time
print(int(time.time() - 3600))
PY
)"
END_TIME="$(date -u +%s 2>/dev/null || python - <<'PY'
import time
print(int(time.time()))
PY
)"

log "Logs Insightsクエリを開始します"
QUERY_ID="$(aws logs start-query \
  --log-group-name "$LOG_GROUP" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --query-string "$QUERY" \
  --region "$REGION" \
  --query queryId \
  --output text)"

echo "QueryId: ${QUERY_ID}"
sleep 5
aws logs get-query-results --query-id "$QUERY_ID" --region "$REGION" --output table

cat <<EOF

使ったクエリ:
${QUERY}

次のステップ:
bash scripts/06_deploy_metric_filter.sh
EOF
