# AWS SRE実践 - CLIコマンド一覧

Udemy講座「AWS SRE実践」で使用するCLIコマンドのリファレンスです。

---

## セクション2: 基盤構築

### CloudFormation スタック作成

**注意: CloudFormation テンプレートを実行すると、TODO アプリが自動的にセットアップされます。手動セットアップは不要です。**

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

# Outputs取得（ALB URL、RDS エンドポイント、DB 名などを確認）
aws cloudformation describe-stacks \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --query 'Stacks[0].Outputs'
```

### TODO アプリの動作確認

```bash
# ALB 経由でアクセス（CloudFormation の Outputs から ALB URL を取得）
curl http://<ALB-DNS-Name>

# TODO アプリのステータス確認（EC2 に SSH 接続後）
sudo systemctl status todo-app

# TODO アプリのログ確認
sudo tail -f /var/log/todo-app.log
```

### 手動セットアップ（参考: CloudFormation を使わない場合）

CloudFormation を使わずに手動でセットアップする場合の手順です。

```bash
# EC2 に SSH 接続
ssh -i ~/.ssh/your-key-pair.pem ec2-user@<EC2-Public-IP>

# TODO アプリのクローン
cd /home/ec2-user
git clone https://github.com/toma1110/sre-todo-app.git
cd sre-todo-app

# 依存関係のインストール
pip3 install -r requirements.txt

# 環境変数の設定（CloudFormation Outputs から取得）
export DB_HOST="<RDS-Endpoint>"
export DB_PORT="3306"
export DB_USER="admin"
export DB_PASSWORD="<Your-Password>"
export DB_NAME="sreapp"
export APP_PORT="8080"

# アプリの起動
python3 app.py
```

### EC2 接続

```bash
# SSH接続
ssh -i ~/.ssh/your-key-pair.pem ec2-user@<EC2-Public-IP>

# アプリケーションログ確認
sudo tail -f /var/log/todo-app.log
sudo systemctl status todo-app
```

### ALB動作確認

```bash
# ALBエンドポイントへアクセス
curl http://<ALB-DNS-Name>

# Apache Benchのインストール（Amazon Linux 2023）
sudo dnf install -y httpd-tools

# 負荷テスト（Apache Bench）
ab -n 1000 -c 10 http://<ALB-DNS-Name>/

# エラーログを発生させるためのテスト（セクション4のメトリクスフィルター学習用）
# /api/data エンドポイント（20%の確率でエラー）
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/data

# /api/process エンドポイント（15%の確率でエラー）
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/process

# ログ確認（JSON形式で出力される）
# 正常ログ例: {"timestamp": "2024-05-04T08:30:00.123Z", "level": "INFO", "message": "Successfully retrieved data", "logger": "app", "requestId": "req-000001"}
# エラーログ例: {"timestamp": "2024-05-04T08:30:01.456Z", "level": "ERROR", "message": "Database connection failed", "logger": "app", "requestId": "req-000002"}
sudo tail -f /var/log/todo-app.log
```

---

## セクション3: CloudWatch監視

### CloudWatch Agent設定

**注意: CloudFormation テンプレート (01-base-infrastructure.yaml) では CloudWatch Agent が自動的にインストール・設定されます。**

```bash
# CloudWatch Agentインストール（手動セットアップの場合）
sudo dnf install -y amazon-cloudwatch-agent

# エージェント状態確認
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a status -m ec2

# 設定ファイル確認（Agentが保存した実際のファイル）
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json

# エージェント再起動（設定ファイルを再作成してから実行）
# 方法1: 設定ファイルを再作成
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<'EOF'
{
  "traces": {
    "traces_collected": {
      "xray": {}
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/todo-app.log",
            "log_group_name": "/aws/ec2/sre-handson/webapp",
            "log_stream_name": "{instance_id}/todo-app"
          }
        ]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 方法2: 既存の設定で再起動（設定変更なし）
sudo systemctl restart amazon-cloudwatch-agent
```

### AWS X-Ray設定

**注意: CloudFormation テンプレート (01-base-infrastructure.yaml) では、CloudWatch Agent の traces セクションで X-Ray トレースを収集します。X-Ray daemon の個別インストールは不要です。**

```bash
# CloudWatch Agent の traces 設定確認
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json

# X-Rayトレース確認
aws xray get-trace-summaries \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --region ap-northeast-1

# サービスマップ取得
aws xray get-service-graph \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --region ap-northeast-1
```

**補足:**
- 既に X-Ray daemon をインストール済みの場合は、そのまま使い続けても問題ありません
- CloudWatch Agent と X-Ray daemon は機能的に同等です

### ダッシュボード作成 (セクション3)

```bash
aws cloudformation deploy \
  --template-file 02-cloudwatch-dashboard.yaml \
  --stack-name sre-handson-dashboard \
  --region ap-northeast-1 \
  --parameter-overrides \
    InstanceId=i-xxxxxxxxxxxxxxxxx \
    ALBFullName=app/sre-handson-alb/xxxxxxxxxx
```

### カスタムメトリクス送信 (セクション3 レクチャー5)

**注意: このセクションではAWS CLIとPythonのboto3を使ってカスタムメトリクスを送信します。CloudFormationテンプレート (03-custom-metrics.yaml) はオプションです。**

#### 方法1: Python (boto3) でカスタムメトリクスを送信

```bash
# boto3インストール（必要な場合）
pip install boto3

# Pythonスクリプト作成
cat > send_metrics.py <<'EOF'
import boto3
from datetime import datetime

client = boto3.client('cloudwatch', region_name='ap-northeast-1')

client.put_metric_data(
    Namespace='MyApp/Production',
    MetricData=[
        {
            'MetricName': 'ErrorCount',
            'Dimensions': [
                {
                    'Name': 'ServiceName',
                    'Value': 'OrderService'
                }
            ],
            'Timestamp': datetime.utcnow(),
            'Value': 5.0,
            'Unit': 'Count'
        }
    ]
)

print('✅ カスタムメトリクスを送信しました')
EOF

# 実行
python send_metrics.py
```

#### 方法2: AWS CLI でカスタムメトリクスを送信

```bash
# CloudShellまたはローカル環境から実行
aws cloudwatch put-metric-data \
  --namespace "MyApp/Production" \
  --metric-name "ErrorCount" \
  --dimensions "Name=ServiceName,Value=OrderService" \
  --value 3 \
  --unit Count \
  --region ap-northeast-1

# 複数メトリクスをまとめて送信
aws cloudwatch put-metric-data \
  --namespace "MyApp/Production" \
  --metric-data \
    'MetricName=ErrorCount,Value=2,Unit=Count' \
    'MetricName=ResponseTime,Value=320,Unit=Milliseconds' \
  --region ap-northeast-1
```

#### 方法3 (オプション): Lambda関数でカスタムメトリクスを自動送信

CloudFormationテンプレートを使用してLambda関数を作成し、定期的にカスタムメトリクスを送信することもできます。

**Lambda関数が送信するメトリクス:**
- Namespace: `SREHandson/Business`
- メトリクス:
  - `ActiveUsers` (Count) - アクティブユーザー数 (ランダム値: 100-500)
  - `OrderCount` (Count) - 注文数 (ランダム値: 10-100)
  - `AppErrorCount` (Count) - エラー数 (ランダム値: 0-10)
- Dimension: `Environment=handson`
- 実行頻度: 1分ごと (EventBridge)

```bash
# Lambda関数デプロイ
aws cloudformation deploy \
  --template-file 03-custom-metrics.yaml \
  --stack-name sre-handson-custom-metrics \
  --region ap-northeast-1 \
  --capabilities CAPABILITY_NAMED_IAM

# Lambda関数を手動実行してテスト
aws lambda invoke \
  --function-name sre-handson-metric-sender \
  --region ap-northeast-1 \
  /tmp/lambda-output.json

cat /tmp/lambda-output.json
```

#### メトリクス確認

```bash
# カスタムメトリクス一覧 (方法1/2の場合)
aws cloudwatch list-metrics \
  --namespace "MyApp/Production" \
  --region ap-northeast-1

# カスタムメトリクス一覧 (方法3 Lambdaの場合)
aws cloudwatch list-metrics \
  --namespace "SREHandson/Business" \
  --region ap-northeast-1

# メトリクスデータ取得 (方法1/2の例)
aws cloudwatch get-metric-statistics \
  --namespace "MyApp/Production" \
  --metric-name ErrorCount \
  --dimensions Name=ServiceName,Value=OrderService \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum Average \
  --region ap-northeast-1

# メトリクスデータ取得 (方法3 Lambdaの例)
aws cloudwatch get-metric-statistics \
  --namespace "SREHandson/Business" \
  --metric-name ActiveUsers \
  --dimensions Name=Environment,Value=handson \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average Maximum Minimum \
  --region ap-northeast-1
```

---

## セクション4: ログ管理

### アプリケーションのログ形式について

このハンズオンのアプリケーションは**JSON形式**でログを出力します。これにより構造化ログとして扱え、メトリクスフィルターやLogs Insightsでの検索が容易になります。

**ログ形式の例:**
```json
{"timestamp": "2024-05-04T08:30:00.123Z", "level": "INFO", "message": "Successfully retrieved data", "logger": "app", "requestId": "req-000001"}
{"timestamp": "2024-05-04T08:30:01.456Z", "level": "ERROR", "message": "Database connection failed", "logger": "app", "requestId": "req-000002"}
```

**エラーログの発生方法:**
- `/api/data` エンドポイント: 20%の確率でエラー（500エラー）
- `/api/process` エンドポイント: 15%の確率でエラー（500エラー）

```bash
# エラーログを発生させる
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/data
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/process
```

### ログメトリクスフィルター作成 (セクション4)

```bash
aws cloudformation deploy \
  --template-file 04-log-metric-filter.yaml \
  --stack-name sre-handson-log-filter \
  --region ap-northeast-1
```

### CloudWatch Logs 操作 (セクション4)

```bash
# ロググループ一覧
aws logs describe-log-groups --region ap-northeast-1

# ログストリーム一覧
aws logs describe-log-streams \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --region ap-northeast-1

# ログ確認
aws logs tail /aws/ec2/sre-handson/webapp --follow --region ap-northeast-1

# ログ検索
aws logs filter-log-events \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --filter-pattern "ERROR" \
  --region ap-northeast-1

# メトリクスフィルター確認
aws logs describe-metric-filters \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --region ap-northeast-1
```

### CloudWatch Logs Insights クエリ (セクション4 レクチャー4)

**注意: Logs Insightsは主にAWSコンソールで使用しますが、CLIでも実行可能です。**

#### コンソールでの使用（推奨）

CloudWatch → Logs Insights → ロググループ選択 → クエリ実行

#### CLI での Logs Insights クエリ実行

```bash
# ① ERRORログ検索（過去1時間）
aws logs start-query \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50' \
  --region ap-northeast-1

# クエリIDを取得（上記コマンドの出力から queryId をコピー）
QUERY_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# クエリ結果を取得
aws logs get-query-results \
  --query-id $QUERY_ID \
  --region ap-northeast-1

# ② requestIdで絞り込み（YOUR_REQUEST_IDを実際の値に置き換え）
aws logs start-query \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message
| filter @requestId = "YOUR_REQUEST_ID"
| sort @timestamp asc' \
  --region ap-northeast-1

# ③ 5分ごとのエラー件数集計
aws logs start-query \
  --log-group-name /aws/ec2/sre-handson/webapp \
  --start-time $(date -u -d '3 hours ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'filter @message like /ERROR/
| stats count(*) as errorCount by bin(5m)
| sort @timestamp asc' \
  --region ap-northeast-1

# ④ Lambda コールドスタート分析（Lambdaログの場合）
aws logs start-query \
  --log-group-name /aws/lambda/your-function-name \
  --start-time $(date -u -d '24 hours ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'filter @type = "REPORT"
| stats avg(@initDuration) as avgInit, pct(@initDuration, 99) as p99Init, count(*) as invocations by bin(1h)' \
  --region ap-northeast-1
```

#### よく使うLogs Insightsクエリパターン

```sql
-- ERRORログを新しい順に50件取得
fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50

-- 特定のrequestIdに関連するすべてのログを時系列で表示
fields @timestamp, @message
| filter @requestId = "YOUR_REQUEST_ID"
| sort @timestamp asc

-- 5分ごとのエラー件数を集計
filter @message like /ERROR/
| stats count(*) as errorCount by bin(5m)
| sort @timestamp asc

-- レスポンスタイムの統計（平均、最大、P99）
filter @type = "REPORT"
| stats avg(@duration), max(@duration), pct(@duration, 99) by bin(5m)

-- 特定のステータスコードをカウント
fields @timestamp, status
| filter status = 500
| stats count() as count500 by bin(1h)

-- IPアドレス別のリクエスト数
fields @timestamp, remote_addr
| stats count() as requestCount by remote_addr
| sort requestCount desc
| limit 20
```

#### Logs Insights クエリのヒント

- `@timestamp`, `@message`, `@logStream` は予約フィールド
- `like /PATTERN/` は正規表現マッチング（大文字小文字区別あり）
- `bin(5m)` は5分単位で集計（1m, 1h, 1d なども可能）
- `pct(field, 99)` は99パーセンタイル値を計算
- `stats` で集計、`sort` でソート、`limit` で件数制限
- タイムスタンプはUTC表示（日本時間 -9時間）

---

## セクション5: アラート設定

### アラーム + SNS作成 (セクション5)

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

### アラーム操作 (セクション5)

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

### SNS操作 (セクション5)

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

## セクション7: インシデント対応

### 負荷テスト・トラブルシューティング (セクション7 レクチャー4)

```bash
# Session Manager接続（ブラウザまたはCLI）
aws ssm start-session \
  --target i-xxxxxxxxxxxxxxxxx \
  --region ap-northeast-1

# EC2内でのトラブルシューティング
# Session Manager接続後に実行
top                    # プロセス・CPU・メモリ確認
htop                   # より見やすいtop（要インストール）
df -h                  # ディスク使用量
free -m                # メモリ使用量
netstat -tuln          # ポート使用状況
journalctl -xe         # systemdログ確認
tail -f /var/log/messages  # システムログ監視

# 負荷テスト用stressコマンド
# EPELリポジトリ有効化（Amazon Linux 2）
sudo amazon-linux-extras install epel -y
sudo yum install stress -y

# Amazon Linux 2023の場合
sudo yum install stress-ng -y

# CPU負荷をかける（4コア、10分間）
stress --cpu 4 --timeout 600

# メモリ負荷をかける（2GB、5分間）
stress --vm 2 --vm-bytes 1G --timeout 300

# 負荷停止
killall stress
```

### Systems Manager Run Command (セクション7 レクチャー4)

```bash
# Run Commandでシェルスクリプト実行
aws ssm send-command \
  --instance-ids i-xxxxxxxxxxxxxxxxx \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["killall stress","systemctl restart myapp"]' \
  --region ap-northeast-1

# コマンド実行結果確認
aws ssm list-command-invocations \
  --command-id <command-id> \
  --details \
  --region ap-northeast-1

# 複数インスタンスに一括実行
aws ssm send-command \
  --targets "Key=tag:Environment,Values=production" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo systemctl restart nginx"]' \
  --region ap-northeast-1
```

---

## セクション9: コスト管理

### コストアラート作成（us-east-1） (セクション9)

```bash
aws cloudformation deploy \
  --template-file 06-cost-alerts.yaml \
  --stack-name sre-handson-cost \
  --region us-east-1 \
  --parameter-overrides \
    NotificationEmail=your@email.com \
    MonthlyBudgetAmount=20
```

### コスト確認 (セクション9)

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

## トラブルシューティング（全般）

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

### EC2 トラブルシューティング（全般）

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

### RDS 接続確認（セクション2）

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
logs tail /aws/ec2/sre-handson/webapp --follow --region ap-northeast-1
```

---

## 参考リンク

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/)
- [CloudFormation CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/)
- [CloudWatch CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/)
- [AWS Cost Explorer CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ce/)
