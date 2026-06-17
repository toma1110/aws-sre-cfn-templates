# AWS SRE実践ハンズオン

Udemyコース **AWS SRE実践講座: CloudWatch・SLO・インシデント対応・コスト最適化** のハンズオン教材です。

このリポジトリでは、AWS上に小さなWebアプリ環境を作り、CloudWatchでメトリクス、ログ、アラーム、インシデント対応、コスト通知までを一通り体験します。

## 最初に読むもの

| 順番 | 資料 | 目的 |
| --- | --- | --- |
| 1 | [環境準備](labs/00-environment-setup.md) | CloudShell、リージョン、料金注意、事前確認 |
| 2 | [サンプルアプリをデプロイ](labs/01-deploy-sample-app.md) | VPC、ALB、EC2、RDS、ログ基盤を作る |
| 3 | [後片付け](labs/99-cleanup.md) | 作成したスタックを削除して課金を止める |

迷ったら、まず `scripts/00_preflight.sh` を実行してください。

```bash
cd aws-sre-cfn-templates
bash scripts/00_preflight.sh
```

## 推奨環境

- AWS CloudShell
- リージョン: `ap-northeast-1`
- AWS CLIが利用できること
- CloudFormation、EC2、RDS、ALB、CloudWatch、SNS、Lambda、Budgetsを作成できる権限

ローカルPCでも実行できますが、講座ではCloudShellを推奨します。アクセスキー管理やツール差分を減らせるためです。

## 料金と削除

このハンズオンは、EC2、RDS、ALB、CloudWatch、Lambda、SNS、Budgetsなどを使います。無料枠内に収まらない場合や、削除忘れがある場合は料金が発生します。

作業が終わったら必ず以下を実行してください。

```bash
bash scripts/99_cleanup.sh
```

削除対象を確認してから進むため、誤操作を避けやすくしています。

## ハンズオン全体の流れ

| 講義 | ラボ | 実行スクリプト |
| --- | --- | --- |
| `s1-l4` 環境セットアップ | [00 環境準備](labs/00-environment-setup.md) | `scripts/00_preflight.sh` |
| `s3-l5` サンプルWebアプリをデプロイ | [01 サンプルアプリをデプロイ](labs/01-deploy-sample-app.md) | `scripts/01_deploy_base.sh` |
| `s4-l4` ダッシュボードを作る | [02 ダッシュボード](labs/02-dashboard.md) | `scripts/03_deploy_dashboard.sh` |
| `s4-l5` カスタムメトリクスを送信 | [03 カスタムメトリクス](labs/03-custom-metrics.md) | `scripts/04_deploy_custom_metrics.sh` |
| `s5-l4` Logs Insightsでエラーを探す | [04 Logs Insights](labs/04-logs-insights.md) | `scripts/05_logs_insights_examples.sh` |
| `s5-l5` ログメトリクスフィルター | [05 メトリクスフィルター](labs/05-log-metric-filter.md) | `scripts/06_deploy_metric_filter.sh` |
| `s6-l4`, `s6-l5` アラート通知 | [06 アラームと通知](labs/06-alarms-and-notification.md) | `scripts/07_deploy_alarms.sh` |
| `s7-l4`, `s8-l4` SLOと模擬インシデント | [07 SLOとインシデント演習](labs/07-slo-and-incident-drill.md) | `scripts/08_incident_drill.sh` |
| `s9-l3` ポストモーテム | [08 ポストモーテム](labs/08-postmortem.md) | テンプレート利用 |
| `s10-l4` コストアラート | [09 コストアラート](labs/09-cost-alerts.md) | `scripts/09_deploy_cost_alerts.sh` |

## クイックスタート

```bash
# 0. 事前確認
bash scripts/00_preflight.sh

# 1. 基盤を作成
export KEY_NAME="your-key-pair-name"
bash scripts/01_deploy_base.sh

# 2. アプリにリクエストを流す
bash scripts/02_generate_traffic.sh

# 3. ダッシュボードを作成
bash scripts/03_deploy_dashboard.sh

# 4. カスタムメトリクスを作成
bash scripts/04_deploy_custom_metrics.sh

# 5. Logs Insightsを試す
bash scripts/05_logs_insights_examples.sh

# 6. ログをメトリクス化
bash scripts/06_deploy_metric_filter.sh

# 7. アラームと通知を作成
export NOTIFICATION_EMAIL="your@example.com"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
bash scripts/07_deploy_alarms.sh

# 8. 模擬インシデント演習
bash scripts/08_incident_drill.sh

# 9. コスト通知を作成
bash scripts/09_deploy_cost_alerts.sh

# 10. 後片付け
bash scripts/99_cleanup.sh
```

## 旧資料

以下の資料は参照用として残しています。

- [CLI_COMMANDS.md](CLI_COMMANDS.md)
- [ハンズオン全体フロー](docs/HANDSON_FLOW.md)
- [CloudWatchの見方](docs/CLOUDWATCH_GUIDE.md)
- [ログとメトリクスの読み取り例](docs/SIGNAL_EXAMPLES.md)
- [SLOドキュメントテンプレート](slo-document-template.md)
- [ポストモーテムテンプレート](postmortem-template.md)

新しく進める場合は、`labs/` と `scripts/` を優先してください。

## トラブルシューティング

### CloudFormationが失敗する

まずイベントを確認します。

```bash
aws cloudformation describe-stack-events \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --max-items 10
```

### アプリにアクセスできない

```bash
bash scripts/90_verify.sh
```

ALBのヘルスチェック、EC2の状態、CloudWatch Logsの出力を順に確認します。

### ログが見えない

ロググループ `/aws/ec2/sre-handson/webapp` を確認してください。EC2起動直後はCloudWatch Agentの反映まで数分かかることがあります。

### 通知メールが届かない

SNSの確認メールを承認しているか確認してください。承認しないとCloudWatch Alarmからメールは届きません。

## ライセンス

MIT
