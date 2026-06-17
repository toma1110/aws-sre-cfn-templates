#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log "AWS CLI と認証状態を確認します"
require_aws

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ARN="$(aws sts get-caller-identity --query Arn --output text)"

cat <<EOF
確認結果:
- Account: ${ACCOUNT_ID}
- Principal: ${ARN}
- Region: ${REGION}
EOF

log "CloudFormationテンプレートの存在を確認します"
for file in \
  01-base-infrastructure.yaml \
  02-cloudwatch-dashboard.yaml \
  03-custom-metrics.yaml \
  04-log-metric-filter.yaml \
  05-alarms-sns.yaml \
  06-cost-alerts.yaml; do
  test -f "${CFN_DIR}/${file}" || { echo "ERROR: ${file} が見つかりません"; exit 1; }
  echo "OK: ${file}"
done

log "EC2キーペア設定を確認します"
if [[ -n "${KEY_NAME:-}" ]]; then
  aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" >/dev/null
  echo "OK: KEY_NAME=${KEY_NAME}"
else
  echo "INFO: KEY_NAME は未設定です。基盤作成前に export KEY_NAME=\"your-key-pair-name\" を設定してください。"
fi

cat <<'EOF'

次のステップ:
1. KEY_NAMEを設定する
2. bash scripts/01_deploy_base.sh

注意:
- このハンズオンはEC2、RDS、ALBなどを作成します。
- 作業後は bash scripts/99_cleanup.sh で削除してください。
EOF
