# ハンズオン全体フロー

操作の目的は「AWSリソースを作ること」ではなく、「障害や遅延の兆候をCloudWatchで見つけ、通知までつなげること」です。

## 進め方

| Step | 操作 | できるようになること | 参照ファイル |
|---|---|---|---|
| 0 | AWS CLI、キーペア、通知先メールを準備する | スタック作成に必要な入力値をそろえる | `README.md` |
| 1 | `01-base-infrastructure.yaml` をデプロイする | ALB / EC2 / RDS / CloudWatch Logs基盤ができる | `README.md` |
| 2 | `AppInstanceId` と `ALBFullName` を取得する | DashboardやAlarmで同じリソースを参照できる | `CLI_COMMANDS.md` |
| 3 | ALBへアクセスし、正常/異常リクエストを発生させる | 監視対象のメトリクスとログが増える | [SIGNAL_EXAMPLES.md](./SIGNAL_EXAMPLES.md) |
| 4 | `02-cloudwatch-dashboard.yaml` をデプロイする | EC2 / ALB / RDS の状態を1画面で確認できる | [CLOUDWATCH_GUIDE.md](./CLOUDWATCH_GUIDE.md) |
| 5 | `03-custom-metrics.yaml` をデプロイする | Lambdaからカスタムメトリクスが送られる | `CLI_COMMANDS.md` |
| 6 | `04-log-metric-filter.yaml` をデプロイする | ERRORログや5xxログをメトリクス化できる | [SIGNAL_EXAMPLES.md](./SIGNAL_EXAMPLES.md) |
| 7 | `05-alarms-sns.yaml` をデプロイする | 悪化したメトリクスをメール/Slackへ通知できる | [CLOUDWATCH_GUIDE.md](./CLOUDWATCH_GUIDE.md) |
| 8 | `06-cost-alerts.yaml` を `us-east-1` にデプロイする | 予算超過や異常コストを検知できる | `README.md` |
| 9 | 逆順にスタックを削除する | 不要な課金を止める | `README.md` |

## 最初に見るべき画面

| タイミング | 画面 | 見るポイント |
|---|---|---|
| `01` 作成後 | CloudFormation Outputs | `ALBEndpoint`, `ALBFullName`, `AppInstanceId` が出ているか |
| ALBアクセス後 | CloudWatch Logs | `/aws/ec2/sre-handson/webapp` にJSONログが出ているか |
| `02` 作成後 | CloudWatch Dashboard | ALB RequestCount、5xxエラー率、P99レイテンシが動くか |
| `04` 作成後 | CloudWatch Metrics | `SREHandson/App` に `ErrorCount` が出るか |
| `05` 作成後 | CloudWatch Alarms | `sre-handson-alb-5xx` などの状態が見えるか |

## 操作のつながり

```text
CloudFormationで基盤を作る
  -> ALBへアクセスしてログ/メトリクスを発生させる
  -> Dashboardで全体を眺める
  -> Logs Insightsで原因を掘る
  -> Metric Filterでログをメトリクス化する
  -> AlarmとSNSで通知する
  -> Cost Alertで費用面も監視する
```

## 迷ったときの順番

1. ALBのURLにアクセスできるか確認する。
2. `/var/log/todo-app.log` にログが出ているかEC2上で確認する。
3. CloudWatch Logsに `/aws/ec2/sre-handson/webapp` が出ているか確認する。
4. DashboardでALB RequestCountが増えるか確認する。
5. `/api/data` または `/api/process` に負荷をかけて、5xxやERRORログが増えるか確認する。

ハンズオン中に「いま何を見ればいいか」が分からなくなった場合は、リソース作成ではなくシグナルの流れに戻って確認してください。
