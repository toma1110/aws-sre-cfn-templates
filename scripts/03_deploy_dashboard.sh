#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws
require_stack "$BASE_STACK"

INSTANCE_ID="$(stack_output "$BASE_STACK" AppInstanceId)"
ALB_FULL_NAME="$(stack_output "$BASE_STACK" ALBFullName)"

log "CloudWatchダッシュボードを作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/02-cloudwatch-dashboard.yaml" \
  --stack-name "$DASHBOARD_STACK" \
  --region "$REGION" \
  --parameter-overrides \
    InstanceId="$INSTANCE_ID" \
    ALBFullName="$ALB_FULL_NAME"

aws cloudformation describe-stacks \
  --stack-name "$DASHBOARD_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

echo
echo "次のステップ: bash scripts/04_deploy_custom_metrics.sh"
