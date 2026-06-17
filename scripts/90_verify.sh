#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

log "CloudFormationスタック状態"
for item in \
  "${BASE_STACK}:${REGION}" \
  "${DASHBOARD_STACK}:${REGION}" \
  "${CUSTOM_METRICS_STACK}:${REGION}" \
  "${LOG_FILTER_STACK}:${REGION}" \
  "${ALARMS_STACK}:${REGION}" \
  "${COST_STACK}:${COST_REGION}"; do
  stack="${item%%:*}"
  region="${item##*:}"
  status="$(aws cloudformation describe-stacks --stack-name "$stack" --region "$region" --query "Stacks[0].StackStatus" --output text 2>/dev/null || true)"
  printf "%-32s %-16s %s\n" "$stack" "$region" "${status:-not-found}"
done

if aws cloudformation describe-stacks --stack-name "$BASE_STACK" --region "$REGION" >/dev/null 2>&1; then
  ALB_ENDPOINT="$(stack_output "$BASE_STACK" ALBEndpoint)"
  INSTANCE_ID="$(stack_output "$BASE_STACK" AppInstanceId)"
  echo
  echo "ALB Endpoint: ${ALB_ENDPOINT}"
  echo "AppInstanceId: ${INSTANCE_ID}"
  echo
  echo "HTTP確認:"
  curl -s -o /dev/null -w "GET / -> %{http_code}\n" "${ALB_ENDPOINT}/" || true
fi

log "ロググループ確認"
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/sre-handson/webapp \
  --region "$REGION" \
  --query "logGroups[].{name:logGroupName,storedBytes:storedBytes}" \
  --output table || true
