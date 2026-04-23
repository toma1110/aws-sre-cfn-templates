# aws-sre-handson

Udemy コース **「【AWS SRE実践】構築から運用へ」** のハンズオン用 CloudFormation テンプレート集です。

## 使い方

各テンプレートは番号順にデプロイしてください。

```
01 → 02 → 03 → 04 → 05 → 06
```

| ファイル | 対応セクション | 内容 |
|---|---|---|
| `sre-handson-base.yml` （= `01-base-infrastructure.yaml`） | セクション2 | VPC / EC2 / ALB / RDS の基盤構築（動画14で使用） |
| `02-cloudwatch-dashboard.yaml` | セクション3 | CloudWatch ダッシュボード作成 |
| `03-custom-metrics.yaml` | セクション3 | Lambda でカスタムメトリクスを送信 |
| `04-log-metric-filter.yaml` | セクション4 | CloudWatch Logs メトリクスフィルター |
| `05-alarms-sns.yaml` | セクション5 | CloudWatch Alarms + Slack 通知 |
| `06-cost-alerts.yaml` | セクション9 | Budgets + Cost Anomaly Detection |

> **注意**: `sre-handson-base.yml` と `01-base-infrastructure.yaml` は同一内容です。動画内で案内している `sre-handson-base.yml` をご利用ください。

## デプロイ方法

### AWS コンソールから

1. [CloudFormation コンソール](https://ap-northeast-1.console.aws.amazon.com/cloudformation/home) を開く
2. 「スタックの作成」→「テンプレートファイルのアップロード」
3. 番号順にデプロイ

### AWS CLI から

```bash
# 01: 基盤構築
aws cloudformation deploy \
  --template-file 01-base-infrastructure.yaml \
  --stack-name sre-handson-base \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DBPassword=YourPassword123 \
    KeyName=your-key-pair-name

# 02: ダッシュボード（01のOutputsを参照）
aws cloudformation deploy \
  --template-file 02-cloudwatch-dashboard.yaml \
  --stack-name sre-handson-dashboard \
  --parameter-overrides \
    InstanceId=i-xxxxxxxxxxxxxxxxx

# 03: カスタムメトリクス
aws cloudformation deploy \
  --template-file 03-custom-metrics.yaml \
  --stack-name sre-handson-custom-metrics \
  --capabilities CAPABILITY_NAMED_IAM

# 04: ログメトリクスフィルター
aws cloudformation deploy \
  --template-file 04-log-metric-filter.yaml \
  --stack-name sre-handson-log-filter

# 05: アラーム + Slack通知
aws cloudformation deploy \
  --template-file 05-alarms-sns.yaml \
  --stack-name sre-handson-alarms \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SlackWebhookURL=https://hooks.slack.com/services/xxx \
    NotificationEmail=your@email.com \
    InstanceId=i-xxxxxxxxxxxxxxxxx \
    ALBFullName=app/sre-handson-alb/xxxxxxxxxx

# 06: コストアラート（us-east-1 でデプロイ）
aws cloudformation deploy \
  --template-file 06-cost-alerts.yaml \
  --stack-name sre-handson-cost \
  --region us-east-1 \
  --parameter-overrides \
    NotificationEmail=your@email.com \
    MonthlyBudgetAmount=3000
```

## 注意事項

- **リージョン**: `ap-northeast-1`（東京）を推奨。`06-cost-alerts.yaml` のみ `us-east-1` が必要
- **費用**: ハンズオン終了後はスタックを削除して課金を止めてください
- **RDS**: `01-base-infrastructure.yaml` の RDS は `db.t3.micro` ですが、起動中は料金が発生します

## スタック削除（後片付け）

```bash
# 番号の逆順で削除
aws cloudformation delete-stack --stack-name sre-handson-cost --region us-east-1
aws cloudformation delete-stack --stack-name sre-handson-alarms
aws cloudformation delete-stack --stack-name sre-handson-log-filter
aws cloudformation delete-stack --stack-name sre-handson-custom-metrics
aws cloudformation delete-stack --stack-name sre-handson-dashboard
aws cloudformation delete-stack --stack-name sre-handson-base
```

## コース情報

- Udemy: [【AWS SRE実践】構築から運用へ](#) ← コース公開後にURLを更新
- 対象: AWS を使い始めて運用に課題を感じているエンジニア
- 前提知識: AWS 基礎（EC2・S3・IAM の操作経験）

## ライセンス

MIT
