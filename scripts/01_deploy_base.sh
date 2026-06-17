#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_aws

if [[ -z "${KEY_NAME:-}" ]]; then
  echo "ERROR: KEY_NAME が未設定です。例: export KEY_NAME=\"your-key-pair-name\"" >&2
  exit 1
fi

if [[ -z "${DB_PASSWORD:-}" ]]; then
  read -r -s -p "RDS用パスワードを入力してください。8文字以上: " DB_PASSWORD
  echo
fi

if [[ "${#DB_PASSWORD}" -lt 8 ]]; then
  echo "ERROR: DB_PASSWORD は8文字以上にしてください。" >&2
  exit 1
fi

confirm "deploy-base" "EC2、RDS、ALBなど料金が発生するAWSリソースを作成します。"

log "基盤スタックを作成または更新します"
aws cloudformation deploy \
  --template-file "${CFN_DIR}/01-base-infrastructure.yaml" \
  --stack-name "$BASE_STACK" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DBPassword="$DB_PASSWORD" \
    KeyName="$KEY_NAME"

log "Outputsを表示します"
aws cloudformation describe-stacks \
  --stack-name "$BASE_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

ALB_ENDPOINT="$(stack_output "$BASE_STACK" ALBEndpoint)"
cat <<EOF

アプリ確認:
curl "${ALB_ENDPOINT}/"
curl "${ALB_ENDPOINT}/api/data"
curl "${ALB_ENDPOINT}/api/process"

次のステップ:
bash scripts/02_generate_traffic.sh
EOF
