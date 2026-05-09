# aws-sre-handson

Udemy コース **「【AWS SRE実践】構築から運用へ」** のハンズオン用 CloudFormation テンプレート集です。

## 使い方

各テンプレートは番号順にデプロイしてください。

```
01 → 02 → 03 → 04 → 05 → 06
```

| ファイル | 対応セクション | 内容 |
|---|---|---|
| `01-base-infrastructure.yaml` | セクション2 | VPC / EC2 / ALB / RDS の基盤構築 |
| `02-cloudwatch-dashboard.yaml` | セクション3 | CloudWatch ダッシュボード作成 |
| `03-custom-metrics.yaml` | セクション3 | Lambda でカスタムメトリクスを送信 |
| `04-log-metric-filter.yaml` | セクション4 | CloudWatch Logs メトリクスフィルター |
| `05-alarms-sns.yaml` | セクション5 | CloudWatch Alarms + Slack 通知 |
| `06-cost-alerts.yaml` | セクション9 | Budgets + Cost Anomaly Detection |

> **注意**: 現在の動画では `01-base-infrastructure.yaml` を使用します。互換性のため `sre-handson-base.yml` はシンボリックリンクとして残してあります（どちらを使っても同じです）。

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
  --region ap-northeast-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DBPassword=YourPassword123 \
    KeyName=your-key-pair-name

# 02: ダッシュボード（01のOutputsを参照）
aws cloudformation deploy \
  --template-file 02-cloudwatch-dashboard.yaml \
  --stack-name sre-handson-dashboard \
  --region ap-northeast-1 \
  --parameter-overrides \
    InstanceId=i-xxxxxxxxxxxxxxxxx \
    ALBFullName=app/sre-handson-alb/xxxxxxxxxx

# 03: カスタムメトリクス
aws cloudformation deploy \
  --template-file 03-custom-metrics.yaml \
  --stack-name sre-handson-custom-metrics \
  --region ap-northeast-1 \
  --capabilities CAPABILITY_NAMED_IAM

# 04: ログメトリクスフィルター
aws cloudformation deploy \
  --template-file 04-log-metric-filter.yaml \
  --stack-name sre-handson-log-filter \
  --region ap-northeast-1

# 05: アラーム + Slack通知
aws cloudformation deploy \
  --template-file 05-alarms-sns.yaml \
  --stack-name sre-handson-alarms \
  --region ap-northeast-1 \
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
    MonthlyBudgetAmount=20
```

## 注意事項

- **リージョン**: `ap-northeast-1`（東京）を推奨。`06-cost-alerts.yaml` のみ `us-east-1` が必要
- **費用**: ハンズオン終了後はスタックを削除して課金を止めてください
- **RDS**: `01-base-infrastructure.yaml` の RDS は `db.t3.micro` ですが、起動中は料金が発生します
- **アプリケーション**: `01-base-infrastructure.yaml` を実行すると、JSON形式のログを出力するFlaskアプリが自動的にセットアップされます

## 前提条件

- AWS アカウント
- EC2 キーペア（SSH 接続用）
- AWS CLI がインストール済み（CLI を使う場合）
- 基本的な Linux コマンドの知識

## トラブルシューティング

### アプリケーションにアクセスできない

1. CloudFormation スタックが正常に作成されたか確認
   ```bash
   aws cloudformation describe-stacks --stack-name sre-handson-base --region ap-northeast-1
   ```

2. EC2 インスタンスが起動しているか確認
   ```bash
   aws ec2 describe-instances --instance-ids <Instance-ID> --region ap-northeast-1
   ```

3. アプリケーションのサービスが起動しているか確認（EC2 に SSH 接続後）
   ```bash
   sudo systemctl status todo-app
   sudo tail -f /var/log/todo-app.log
   ```

4. セキュリティグループで ALB からポート 8080 が許可されているか確認

### CloudWatch Agent が動作しない

1. CloudWatch Agent のステータス確認
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status -m ec2
   ```

2. CloudWatch Agent のログ確認
   ```bash
   sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
   ```

3. IAM ロールに `CloudWatchAgentServerPolicy` が付与されているか確認

### X-Ray トレースが表示されない

1. IAM ロールに以下のポリシーが付与されているか確認
   - `AWSXRayDaemonWriteAccess`（トレース送信用）
   - `AWSXRayReadOnlyAccess`（トレース確認用）

2. CloudWatch Agent の traces セクションが有効になっているか確認
   ```bash
   sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json | grep -A 5 traces
   ```

3. アプリケーションに X-Ray SDK が組み込まれているか確認

### ロググループにログが出力されない

1. ロググループ `/aws/ec2/sre-handson/webapp` が作成されているか確認
   ```bash
   aws logs describe-log-groups --log-group-name-prefix /aws/ec2/sre-handson/webapp --region ap-northeast-1
   ```

2. CloudWatch Agent の設定を確認
   ```bash
   sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
   ```

3. ログファイルが存在するか確認
   ```bash
   ls -la /var/log/todo-app.log
   ```

### RDS に接続できない

1. RDS エンドポイントを確認
   ```bash
   aws cloudformation describe-stacks \
     --stack-name sre-handson-base \
     --region ap-northeast-1 \
     --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
     --output text
   ```

2. セキュリティグループで EC2 から RDS へのポート 3306 が許可されているか確認

3. DB 名、ユーザー名、パスワードが正しいか確認
   - DB 名: `sreapp`
   - ユーザー名: `admin`
   - パスワード: CloudFormation パラメータで指定した値

## よくある質問

### Q. X-Ray daemon をインストールする必要はありますか？

A. いいえ、不要です。CloudWatch Agent の traces セクションで X-Ray トレースを収集します。既に X-Ray daemon をインストール済みの場合は、そのまま使い続けても問題ありません。

### Q. アプリケーションのポートは何番ですか？

A. ポート 8080 です。ALB はポート 80 でリクエストを受け付け、ポート 8080 でバックエンドに転送します。

### Q. ログストリームは手動で作成する必要がありますか？

A. いいえ、CloudWatch Agent がログを送信する際に自動的に作成されます。ロググループのみ事前に作成されている必要があります（CloudFormation テンプレートで自動作成されます）。

### Q. 手動でセットアップする方法はありますか？

A. はい、`CLI_COMMANDS.md` に手動セットアップ手順が記載されています。ただし、CloudFormation を使った自動セットアップを推奨します。

## スタック削除（後片付け）

```bash
# 番号の逆順で削除
aws cloudformation delete-stack --stack-name sre-handson-cost --region us-east-1
aws cloudformation delete-stack --stack-name sre-handson-alarms --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-log-filter --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-custom-metrics --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-dashboard --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-base --region ap-northeast-1
```

## コース情報

- Udemy: [【AWS SRE実践】構築から運用へ](https://www.udemy.com/course/aws-sre-cloudwatch/) 
- 対象: AWS を使い始めて運用に課題を感じているエンジニア
- 前提知識: AWS 基礎（EC2・S3・IAM の操作経験）

## ライセンス

MIT
