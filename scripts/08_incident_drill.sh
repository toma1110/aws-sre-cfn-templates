#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws
require_stack "$BASE_STACK"

INSTANCE_ID="$(stack_output "$BASE_STACK" AppInstanceId)"
DURATION="${DURATION:-600}"
CPU_WORKERS="${CPU_WORKERS:-4}"

cat <<EOF
模擬インシデント:
- 対象EC2: ${INSTANCE_ID}
- 負荷時間: ${DURATION}秒
- CPU worker: ${CPU_WORKERS}
EOF

confirm "start-incident-drill" "Systems Manager Run CommandでEC2にCPU負荷を発生させます。"

COMMAND_ID="$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "SRE handson incident drill CPU load" \
  --parameters "commands=[\"sudo dnf install -y stress-ng\",\"cd ~\",\"stress-ng --cpu ${CPU_WORKERS} --timeout ${DURATION}\"]" \
  --region "$REGION" \
  --query "Command.CommandId" \
  --output text)"

echo "CommandId: ${COMMAND_ID}"

cat <<EOF

確認ポイント:
- CloudWatch DashboardでCPU使用率を見る
- Alarm状態を見る
- インシデント用タイムラインを書く

停止したい場合:
aws ssm send-command --instance-ids ${INSTANCE_ID} --document-name AWS-RunShellScript --parameters 'commands=["sudo killall stress-ng || true"]' --region ${REGION}
EOF
