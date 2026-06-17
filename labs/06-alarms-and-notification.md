# 06 アラームと通知

対応講義:

- `s6-l4` SNS通知の設定
- `s6-l5` ハンズオン: アラートを設計してSlackに飛ばす

## 目的

CloudWatch Alarm、SNS、メール、Slack通知の流れを作ります。

## 事前準備

- 通知先メールアドレス
- Slack Incoming Webhook URL
- `sre-handson-base` スタック作成済み

Slack Webhook URLは秘密値です。動画、画面共有、Issue、Gitに載せないでください。

## 手順

```bash
export NOTIFICATION_EMAIL="your@example.com"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
bash scripts/07_deploy_alarms.sh
```

## 期待結果

CloudFormation Outputsに以下が表示されます。

- `SNSTopicArn`
- `SlackFunctionName`

確認ポイント:

- SNS確認メールを承認する
- CloudWatch Alarmsに以下が作られている
  - `sre-handson-cpu-high`
  - `sre-handson-alb-5xx`
  - `sre-handson-alb-latency`
  - `sre-handson-app-error`

## 通知を確認する

```bash
bash scripts/02_generate_traffic.sh
```

ALB 5系エラーやアプリエラーが増えたら、アラーム状態と通知を確認します。

## 次へ

[07 SLOとインシデント演習](07-slo-and-incident-drill.md) に進みます。
