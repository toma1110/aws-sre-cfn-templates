#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

LOG_GROUP="${LOG_GROUP:-/aws/ec2/sre-handson/webapp}"

log "ログメトリクスフィルターを作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/04-log-metric-filter.yaml" \
  --stack-name "$LOG_FILTER_STACK" \
  --region "$REGION" \
  --parameter-overrides LogGroupName="$LOG_GROUP"

aws cloudformation describe-stacks \
  --stack-name "$LOG_FILTER_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

echo
echo "次のステップ: bash scripts/07_deploy_alarms.sh"
