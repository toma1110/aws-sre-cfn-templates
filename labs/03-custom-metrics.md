# 03 カスタムメトリクス

対応講義: `s4-l5` ハンズオン: カスタムメトリクスを送信する

## 目的

アプリやビジネス観点の数値をCloudWatch Metricsへ送る流れを体験します。

## 手順

```bash
bash scripts/04_deploy_custom_metrics.sh
```

このスクリプトはLambdaを作成し、一度実行して `SREHandson/Business` 名前空間へメトリクスを送信します。

## 期待結果

CloudFormation Outputsに以下が表示されます。

- `FunctionName`
- `MetricNamespace`
- `CloudWatchURL`

CloudWatch Metricsで `SREHandson/Business` が見えることを確認します。反映まで数分かかる場合があります。

## 次へ

[04 Logs Insights](04-logs-insights.md) に進みます。
