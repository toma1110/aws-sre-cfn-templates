#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

cat <<EOF
削除予定:
- ${COST_STACK} (${COST_REGION})
- ${ALARMS_STACK} (${REGION})
- ${LOG_FILTER_STACK} (${REGION})
- ${CUSTOM_METRICS_STACK} (${REGION})
- ${DASHBOARD_STACK} (${REGION})
- ${BASE_STACK} (${REGION})

削除後、EC2、RDS、ALBなどの課金対象が止まります。
EOF

confirm "delete-sre-handson" "CloudFormationスタックを逆順で削除します。"

delete_stack() {
  local stack_name="$1"
  local region="$2"
  if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$region" >/dev/null 2>&1; then
    log "Deleting ${stack_name} (${region})"
    aws cloudformation delete-stack --stack-name "$stack_name" --region "$region"
    log "Waiting for ${stack_name} deletion to complete"
    aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region "$region"
    log "Deleted ${stack_name}"
  else
    log "Skip ${stack_name}: not found"
  fi
}

delete_stack "$COST_STACK" "$COST_REGION"
delete_stack "$ALARMS_STACK" "$REGION"
delete_stack "$LOG_FILTER_STACK" "$REGION"
delete_stack "$CUSTOM_METRICS_STACK" "$REGION"
delete_stack "$DASHBOARD_STACK" "$REGION"
delete_stack "$BASE_STACK" "$REGION"

cat <<'EOF'

削除が完了しました。
念のための確認:
bash scripts/90_verify.sh

CloudFormationコンソールでも、DELETE_COMPLETEまたは対象なしになっていることを確認してください。
EOF
