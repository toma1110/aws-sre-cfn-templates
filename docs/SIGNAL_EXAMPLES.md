# ログとメトリクスの読み取り例

このハンズオンでは、正常なリクエストと意図的なエラーを発生させて、CloudWatchでどう見えるかを確認します。

## 正常系ログ

`/api/data` が成功したときの例です。

```json
{"timestamp":"2026-05-14T08:30:00.123Z","level":"INFO","message":"Request completed successfully","logger":"app","requestId":"req-000001","remote_addr":"10.0.1.50","method":"GET","path":"/api/data","status":200,"duration":125.45}
```

見るポイント:

- `level` が `INFO`
- `status` が `200`
- `duration` はミリ秒
- `requestId` は調査時のキー

## 異常系ログ

`/api/process` がHTTP 500を返したときの例です。

```json
{"timestamp":"2026-05-14T08:30:01.456Z","level":"ERROR","message":"Request failed with status 500","logger":"app","requestId":"req-000002","remote_addr":"10.0.1.51","method":"GET","path":"/api/process","status":500,"duration":734.67}
```

見るポイント:

- `level` が `ERROR`
- `status` が `500`
- `path` で失敗したエンドポイントを確認する
- `duration` が大きい場合、遅延とエラーが同時に起きている可能性を見る

## エラーを発生させる

`/api/data` は約20%、`/api/process` は約15%の確率でHTTP 500を返します。

```bash
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/data
ab -n 100 -c 5 http://<ALB-DNS-Name>/api/process
```

`ab` がない環境では、`curl` を繰り返しても確認できます。

```bash
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{http_code}\n" http://<ALB-DNS-Name>/api/data
done
```

## Logs Insightsクエリ

ERRORログを新しい順に見る:

```sql
fields @timestamp, level, message, requestId, path, status, duration
| filter level = "ERROR"
| sort @timestamp desc
| limit 50
```

5分ごとのERROR件数を見る:

```sql
filter level = "ERROR"
| stats count(*) as errorCount by bin(5m)
| sort @timestamp asc
```

ステータスコード別に件数を見る:

```sql
filter status != "N/A"
| stats count(*) as requestCount by status
| sort requestCount desc
```

エンドポイント別の500件数を見る:

```sql
filter path != "N/A" and status = 500
| stats count(*) as errors by path
| sort errors desc
```

遅いリクエストを見る:

```sql
fields @timestamp, requestId, path, status, duration
| filter duration > 500
| sort duration desc
| limit 50
```

P99レイテンシを見る:

```sql
filter duration != "N/A"
| stats avg(duration) as avg_ms, max(duration) as max_ms, pct(duration, 99) as p99_ms by bin(5m)
| sort @timestamp asc
```

## Dashboardでの読み取り

| 現象 | 見るグラフ | 判断 |
|---|---|---|
| ALBにアクセスしたのに反応がない | ALB リクエスト数 | 増えなければURL、ALB、セキュリティグループを確認 |
| 500が多い | ALB 5xxエラー率 / `ErrorCount` | エンドポイント別にLogs Insightsで掘る |
| 反応が遅い | ALB レスポンスタイム(P99) / `duration` | `/api/process` の遅延ログを確認 |
| EC2が重い | EC2 CPU / メモリ | CPUやメモリがしきい値付近か確認 |

## Alarmでの読み取り

| AlarmName | ALARMになったときに見るもの |
|---|---|
| `sre-handson-cpu-high` | EC2 CPU、アプリプロセス、負荷発生命令 |
| `sre-handson-alb-5xx` | ALB 5xx、Logs InsightsのERRORログ |
| `sre-handson-alb-latency` | P99レイテンシ、`duration > 500` のログ |
| `sre-handson-app-error` | `SREHandson/App` の `ErrorCount`、エンドポイント別ERROR件数 |

## メトリクス確認CLI

ALB 5xx件数:

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value="${ALB_FULL_NAME}" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-northeast-1
```

アプリERROR件数:

```bash
aws cloudwatch get-metric-statistics \
  --namespace SREHandson/App \
  --metric-name ErrorCount \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-northeast-1
```
