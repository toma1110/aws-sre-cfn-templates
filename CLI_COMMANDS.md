# AWS SRE実践 - CLIコマンド一覧

Udemy講座「AWS SRE実践」で使用するCLIコマンドのリファレンスです。

---

## セクション2: 基盤構築

### CloudFormation スタック作成

```bash
aws cloudformation deploy \
  --template-file 01-base-infrastructure.yaml \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DBPassword=YourPassword123 \
    KeyName=your-key-pair-name
```

### スタック情報確認

```bash
# スタック一覧
aws cloudformation list-stacks --region ap-northeast-1

# スタック詳細
aws cloudformation describe-stacks \
  --stack-name sre-handson-base \
  --region ap-northeast-1

# Outputs取得
aws cloudformation describe-stacks \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --query 'Stacks[0].Outputs'
```

### EC2 接続

```bash
# SSH接続
ssh -i ~/.ssh/your-key-pair.pem ec2-user@<EC2-Public-IP>

# アプリケーションログ確認
sudo tail -f /var/log/cloud-init-output.log
sudo systemctl status myapp
```

### ALB動作確認

```bash
# ALBエンドポイントへアクセス
curl http://<ALB-DNS-Name>

# 負荷テスト（Apache Bench）
ab -n 1000 -c 10 http://<ALB-DNS-Name>/
```

---

## セクション3: CloudWatch監視

### ダッシュボード作成

```bash
aws cloudformation deploy \
  --template-file 02-cloudwatch-dashboard.yaml \
  --stack-name sre-handson-dashboard \
  --region ap-northeast-1 \
  --parameter-overrides \
    InstanceId=i-xxxxxxxxxxxxxxxxx \
    ALBFullName=app/sre-handson-alb/xxxxxxxxxx
```

### カスタムメトリクス送信

```bash
# Lambda関数デプロイ
aws cloudformation deploy \
  --template-file 03-custom-metrics.yaml \
  --stack-name sre-handson-custom-metrics \
  --region ap-northeast-1 \
  --capabilities CAPABILITY_NAMED_IAM

# メトリクス確認
aws cloudwatch list-metrics \
  --namespace "SRE/Handson" \
  --region ap-northeast-1

# メトリクスデータ取得
aws cloudwatch get-metric-statistics \
  --namespace "SRE/Handson" \
  --metric-name ActiveConnections \
  --dimensions Name=Environment,Value=Production \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average \
  --region ap-northeast-1
```

---

## セクション4: ログ管理

### ログメトリクスフィルター作成

```bash
aws cloudformation deploy \
  --template-file 04-log-metric-filter.yaml \
  --stack-name sre-handson-log-filter \
  --region ap-northeast-1
```

### CloudWatch Logs 操作

```bash
# ロググループ一覧
aws logs describe-log-groups --region ap-northeast-1

# ログストリーム一覧
aws logs describe-log-streams \
  --log-group-name /aws/ec2/myapp \
  --region ap-northeast-1

# ログ確認
aws logs tail /aws/ec2/myapp --follow --region ap-northeast-1

# ログ検索
aws logs filter-log-events \
  --log-group-name /aws/ec2/myapp \
  --filter-pattern "ERROR" \
  --region ap-northeast-1

# メトリクスフィルター確認
aws logs describe-metric-filters \
  --log-group-name /aws/ec2/myapp \
  --region ap-northeast-1
```

---

## セクション5: アラート設定

### アラーム + SNS作成

```bash
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
```

### アラーム操作

```bash
# アラーム一覧
aws cloudwatch describe-alarms --region ap-northeast-1

# 特定アラームの詳細
aws cloudwatch describe-alarms \
  --alarm-names "sre-handson-high-cpu" \
  --region ap-northeast-1

# アラーム履歴
aws cloudwatch describe-alarm-history \
  --alarm-name "sre-handson-high-cpu" \
  --region ap-northeast-1

# アラームテスト（手動でアラーム状態に変更）
aws cloudwatch set-alarm-state \
  --alarm-name "sre-handson-high-cpu" \
  --state-value ALARM \
  --state-reason "Testing alarm notification" \
  --region ap-northeast-1
```

### SNS操作

```bash
# SNSトピック一覧
aws sns list-topics --region ap-northeast-1

# サブスクリプション確認
aws sns list-subscriptions --region ap-northeast-1

# テストメッセージ送信
aws sns publish \
  --topic-arn arn:aws:sns:ap-northeast-1:123456789012:sre-handson-alerts \
  --message "Test notification" \
  --subject "Test Alert" \
  --region ap-northeast-1
```

---

## セクション9: コスト管理

### コストアラート作成（us-east-1）

```bash
aws cloudformation deploy \
  --template-file 06-cost-alerts.yaml \
  --stack-name sre-handson-cost \
  --region us-east-1 \
  --parameter-overrides \
    NotificationEmail=your@email.com \
    MonthlyBudgetAmount=20
```

### コスト確認

```bash
# 今月のコスト取得
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1

# サービス別コスト
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1

# Budget確認
aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --region us-east-1
```

---

## トラブルシューティング

### CloudFormation エラー確認

```bash
# スタックイベント確認
aws cloudformation describe-stack-events \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --max-items 20

# 失敗したリソースのみ表示
aws cloudformation describe-stack-events \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### EC2 トラブルシューティング

```bash
# インスタンス状態確認
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxxxxxx \
  --region ap-northeast-1

# システムログ取得
aws ec2 get-console-output \
  --instance-id i-xxxxxxxxxxxxxxxxx \
  --region ap-northeast-1

# セキュリティグループ確認
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxxxxxxxxxxx \
  --region ap-northeast-1
```

### RDS 接続確認

```bash
# RDSエンドポイント確認
aws rds describe-db-instances \
  --db-instance-identifier sre-handson-db \
  --region ap-northeast-1 \
  --query 'DBInstances[0].Endpoint'

# EC2からRDS接続テスト
mysql -h <RDS-Endpoint> -u admin -p
```

---

## クリーンアップ

### 全スタック削除

```bash
# 逆順で削除
aws cloudformation delete-stack --stack-name sre-handson-cost --region us-east-1
aws cloudformation delete-stack --stack-name sre-handson-alarms --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-log-filter --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-custom-metrics --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-dashboard --region ap-northeast-1
aws cloudformation delete-stack --stack-name sre-handson-base --region ap-northeast-1

# 削除完了待機
aws cloudformation wait stack-delete-complete \
  --stack-name sre-handson-base \
  --region ap-northeast-1
```

### 削除確認

```bash
# スタック状態確認
aws cloudformation list-stacks \
  --stack-status-filter DELETE_COMPLETE \
  --region ap-northeast-1
```

---

## 便利なエイリアス設定

```bash
# ~/.bashrc または ~/.zshrc に追加
alias cfn='aws cloudformation'
alias cw='aws cloudwatch'
alias logs='aws logs'

# 使用例
cfn describe-stacks --stack-name sre-handson-base --region ap-northeast-1
cw describe-alarms --region ap-northeast-1
logs tail /aws/ec2/myapp --follow --region ap-northeast-1
```

---

## 参考リンク

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/)
- [CloudFormation CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/)
- [CloudWatch CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/)
- [AWS Cost Explorer CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ce/)
