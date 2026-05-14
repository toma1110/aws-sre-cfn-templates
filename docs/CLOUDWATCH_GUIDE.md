# CloudWatchの見方

このハンズオンでは、CloudWatchを「見る場所」ごとに分けて使います。Dashboardは全体把握、Logs Insightsは原因調査、Alarmsは通知、Metricsは個別確認に使います。

## Dashboard

`02-cloudwatch-dashboard.yaml` は `SRE-Handson-Dashboard` を作成します。

| ウィジェット | Namespace / Metric | 見方 |
|---|---|---|
| EC2 CPU使用率 | `AWS/EC2` / `CPUUtilization` | インスタンス負荷が高すぎないか見る |
| EC2 メモリ使用率 | `CWAgent` / `mem_used_percent` | CloudWatch Agent経由のOSメトリクスを見る |
| EC2 ディスク使用率 | `CWAgent` / `disk_used_percent` | ルートディスクの逼迫を見る |
| ALB リクエスト数 | `AWS/ApplicationELB` / `RequestCount` | 負荷をかけたときにアクセスが届いているか見る |
| ALB 5xxエラー率 | Metric Math | 失敗率が上がっていないか見る |
| ALB レスポンスタイム(P99) | `AWS/ApplicationELB` / `TargetResponseTime` | SLOの目安である1秒を超えていないか見る |
| RDS CPU / Connections / FreeStorage | `AWS/RDS` | DBの基本状態を見る |

最初は `ALB リクエスト数` が増えるかを見てください。増えない場合、アプリ以前にALBのURL、セキュリティグループ、ターゲットグループを確認します。

## Logs Insights

対象ロググループは `/aws/ec2/sre-handson/webapp` です。FlaskアプリはJSONログを出すため、`level`, `requestId`, `path`, `status`, `duration` をフィールドとして検索できます。

```sql
fields @timestamp, level, message, requestId, path, status, duration
| filter level = "ERROR"
| sort @timestamp desc
| limit 50
```

`requestId` は、1つのリクエストを追うための手がかりです。エラーの詳細を追うときは、まずERRORログを見つけ、その `requestId` で絞り込んでください。

## Metric Filter

`04-log-metric-filter.yaml` は次のメトリクスを作ります。

| FilterName | FilterPattern | Namespace / Metric | 意味 |
|---|---|---|---|
| `sre-handson-error-filter` | `{ $.level = "ERROR" }` | `SREHandson/App` / `ErrorCount` | ERRORログの件数 |
| `sre-handson-5xx-filter` | `{ $.status = "500" }` | `SREHandson/App` / `HTTP5xxCount` | アプリログ上のHTTP 500件数 |

Metric Filterは「ログ検索」ではなく「ログをメトリクスへ変換する仕組み」です。Alarmで扱いたい値だけをメトリクス化します。

## Alarms

`05-alarms-sns.yaml` は4つのアラームを作成します。

| AlarmName | 条件 | 通知先 |
|---|---|---|
| `sre-handson-cpu-high` | EC2 CPUが80%を超える状態が2回続く | SNS |
| `sre-handson-alb-5xx` | ALB Target 5xxが5分で10件を超える | SNS |
| `sre-handson-alb-latency` | ALB P99レイテンシが1秒を超える状態が3回続く | SNS |
| `sre-handson-app-error` | `ErrorCount` が5分で20件を超える | SNS |

SNSトピック `sre-handson-alerts` は、メール購読とSlack通知用Lambdaに接続されます。メール購読は確認メールの承認が必要です。

## Metrics

よく使うNamespaceは次の通りです。

| Namespace | 例 | 使いどころ |
|---|---|---|
| `AWS/EC2` | `CPUUtilization` | EC2標準メトリクス |
| `CWAgent` | `mem_used_percent`, `disk_used_percent` | CloudWatch Agentが送るOSメトリクス |
| `AWS/ApplicationELB` | `RequestCount`, `HTTPCode_Target_5XX_Count`, `TargetResponseTime` | ALB経由のユーザー影響を見る |
| `AWS/RDS` | `CPUUtilization`, `DatabaseConnections` | RDSの基本状態を見る |
| `SREHandson/App` | `ErrorCount`, `HTTP5xxCount` | アプリログ由来のメトリクス |
| `SREHandson/Business` | `ActiveUsers`, `OrderCount`, `AppErrorCount` | Lambdaが送るサンプル業務メトリクス |

## 使い分け

| やりたいこと | 使う場所 |
|---|---|
| いま全体が正常そうか見たい | Dashboard |
| エラーの原因を調べたい | Logs Insights |
| 数値がしきい値を超えたら気づきたい | Alarms |
| ログにしかない値をしきい値化したい | Metric Filter |
| CLIで値を取得したい | `aws cloudwatch get-metric-statistics` |
