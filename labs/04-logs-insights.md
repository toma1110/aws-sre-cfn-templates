# 04 Logs Insights

対応講義: `s5-l4` ハンズオン: Logs Insightsでエラーを探す

## 目的

CloudWatch Logs Insightsで、アプリのJSONログからエラーや遅延を探します。

## 事前準備

ログを増やすため、必要に応じて以下を実行します。

```bash
bash scripts/02_generate_traffic.sh
```

## 手順

```bash
bash scripts/05_logs_insights_examples.sh
```

## 代表クエリ

```sql
fields @timestamp, level, message, requestId, path, status, duration
| filter status >= 500 or level = "ERROR"
| sort @timestamp desc
| limit 20
```

遅いリクエストを見る場合:

```sql
fields @timestamp, path, status, duration, requestId
| filter duration > 500
| sort duration desc
| limit 20
```

## 期待結果

- `/api/data` や `/api/process` の5系エラーが見える
- `requestId`、`path`、`status`、`duration` を使って調査できる

## 次へ

[05 メトリクスフィルター](05-log-metric-filter.md) に進みます。
