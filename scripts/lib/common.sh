#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-1}}"
BASE_STACK="${BASE_STACK:-sre-handson-base}"
DASHBOARD_STACK="${DASHBOARD_STACK:-sre-handson-dashboard}"
CUSTOM_METRICS_STACK="${CUSTOM_METRICS_STACK:-sre-handson-custom-metrics}"
LOG_FILTER_STACK="${LOG_FILTER_STACK:-sre-handson-log-filter}"
ALARMS_STACK="${ALARMS_STACK:-sre-handson-alarms}"
COST_STACK="${COST_STACK:-sre-handson-cost-alerts}"
COST_REGION="${COST_REGION:-us-east-1}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
CFN_DIR="${REPO_DIR}/cloudformation"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: '$1' が見つかりません。CloudShellまたはAWS CLI環境で実行してください。" >&2
    exit 1
  fi
}

require_aws() {
  require_cmd aws
  aws sts get-caller-identity >/dev/null
}

stack_output() {
  local stack_name="$1"
  local output_key="$2"
  local region="${3:-$REGION}"
  aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$region" \
    --query "Stacks[0].Outputs[?OutputKey=='${output_key}'].OutputValue" \
    --output text
}

require_stack() {
  local stack_name="$1"
  local region="${2:-$REGION}"
  aws cloudformation describe-stacks --stack-name "$stack_name" --region "$region" >/dev/null
}

confirm() {
  local phrase="$1"
  local message="$2"
  echo "$message"
  read -r -p "続けるには '${phrase}' と入力してください: " answer
  if [[ "$answer" != "$phrase" ]]; then
    echo "中止しました。"
    exit 1
  fi
}
