#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

if [[ -z "${NOTIFICATION_EMAIL:-}" ]]; then
  read -r -p "コスト通知先メールアドレスを入力してください: " NOTIFICATION_EMAIL
fi

MONTHLY_BUDGET_AMOUNT="${MONTHLY_BUDGET_AMOUNT:-20}"
ANOMALY_THRESHOLD_AMOUNT="${ANOMALY_THRESHOLD_AMOUNT:-5}"

confirm "deploy-cost-alerts" "BudgetsとCost Anomaly Detection関連リソースを作成します。"

log "コスト通知スタックを ${COST_REGION} に作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/06-cost-alerts.yaml" \
  --stack-name "$COST_STACK" \
  --region "$COST_REGION" \
  --parameter-overrides \
    NotificationEmail="$NOTIFICATION_EMAIL" \
    MonthlyBudgetAmount="$MONTHLY_BUDGET_AMOUNT" \
    AnomalyThresholdAmount="$ANOMALY_THRESHOLD_AMOUNT"

aws cloudformation describe-stacks \
  --stack-name "$COST_STACK" \
  --region "$COST_REGION" \
  --query "Stacks[0].Outputs" \
  --output table

echo
echo "次のステップ: bash scripts/99_cleanup.sh"
