#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws
require_stack "$BASE_STACK"

if [[ -z "${NOTIFICATION_EMAIL:-}" ]]; then
  read -r -p "通知先メールアドレスを入力してください: " NOTIFICATION_EMAIL
fi

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  read -r -s -p "Slack Incoming Webhook URLを入力してください: " SLACK_WEBHOOK_URL
  echo
fi

INSTANCE_ID="$(stack_output "$BASE_STACK" AppInstanceId)"
ALB_FULL_NAME="$(stack_output "$BASE_STACK" ALBFullName)"

log "CloudWatch Alarms、SNS、Slack通知Lambdaを作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/05-alarms-sns.yaml" \
  --stack-name "$ALARMS_STACK" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail="$NOTIFICATION_EMAIL" \
    SlackWebhookURL="$SLACK_WEBHOOK_URL" \
    InstanceId="$INSTANCE_ID" \
    ALBFullName="$ALB_FULL_NAME"

aws cloudformation describe-stacks \
  --stack-name "$ALARMS_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

cat <<'EOF'

重要:
- SNS確認メールが届いたら承認してください。
- Slack Webhook URLは第三者に共有せず、IssueやGitなどに記録しないでください。

次のステップ:
bash scripts/08_incident_drill.sh
EOF
