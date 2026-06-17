# 05 メトリクスフィルター

対応講義: `s5-l5` ハンズオン: CloudWatch Logsメトリクスフィルター

## 目的

ログに出たエラーをCloudWatch Metricsとして扱えるようにします。

## 手順

```bash
bash scripts/06_deploy_metric_filter.sh
```

## 期待結果

CloudFormation Outputsに以下が表示されます。

- `LogGroupName`
- `MetricNamespace`
- `LogsInsightsURL`

作成されるメトリクス:

- Namespace: `SREHandson/App`
- MetricName: `ErrorCount`

## 確認

```bash
bash scripts/02_generate_traffic.sh
```

その後、CloudWatch Metricsで `SREHandson/App` の `ErrorCount` を確認します。反映まで数分かかる場合があります。

## 次へ

[06 アラームと通知](06-alarms-and-notification.md) に進みます。
