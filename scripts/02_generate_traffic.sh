#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws
require_cmd curl
require_stack "$BASE_STACK"

ALB_ENDPOINT="$(stack_output "$BASE_STACK" ALBEndpoint)"
COUNT="${COUNT:-80}"
SLEEP_SECONDS="${SLEEP_SECONDS:-0.2}"

log "ALBへリクエストを送り、ログとメトリクスを発生させます"
echo "Endpoint: ${ALB_ENDPOINT}"
echo "Count: ${COUNT}"

for i in $(seq 1 "$COUNT"); do
  path="/"
  case $((i % 3)) in
    1) path="/api/data" ;;
    2) path="/api/process" ;;
  esac
  code="$(curl -s -o /dev/null -w "%{http_code}" "${ALB_ENDPOINT}${path}" || true)"
  printf "%03d %s -> %s\n" "$i" "$path" "$code"
  sleep "$SLEEP_SECONDS"
done

cat <<EOF

確認ポイント:
- CloudWatch Logs: /aws/ec2/sre-handson/webapp
- ALBメトリクス: RequestCount, HTTPCode_Target_5XX_Count, TargetResponseTime

次のステップ:
bash scripts/03_deploy_dashboard.sh
EOF
