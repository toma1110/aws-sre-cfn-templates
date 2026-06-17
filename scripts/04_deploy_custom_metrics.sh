#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

log "カスタムメトリクス送信用Lambdaを作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/03-custom-metrics.yaml" \
  --stack-name "$CUSTOM_METRICS_STACK" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM

FUNCTION_NAME="$(stack_output "$CUSTOM_METRICS_STACK" FunctionName)"

log "Lambdaを一度実行してメトリクスを送信します"
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  /tmp/sre-handson-custom-metrics-response.json >/dev/null

cat /tmp/sre-handson-custom-metrics-response.json || true
echo
aws cloudformation describe-stacks \
  --stack-name "$CUSTOM_METRICS_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

echo
echo "次のステップ: bash scripts/05_logs_insights_examples.sh"
