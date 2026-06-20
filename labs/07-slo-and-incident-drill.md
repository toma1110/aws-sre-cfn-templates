# 07 SLOとインシデント演習

対応講義:

- `s7-l4` ハンズオン: 自分のサービスのSLOを設計する
- `s8-l3` AWS Runbook / Systems Managerの活用
- `s8-l4` ハンズオン: 模擬インシデント対応演習

## 目的

SLOを言葉で決めるだけでなく、実際のメトリクスとインシデント対応に接続します。

## SLO設計

[SLOドキュメントテンプレート](../slo-document-template.md) を開き、以下を埋めます。

- サービス名
- ユーザー影響
- SLI
- SLO目標
- エラーバジェット
- アラート条件
- 見直しタイミング

例:

- SLI: ALBの成功率
- SLO: 28日間で99.0%以上
- 補助指標: p99レイテンシ、5系のエラー率

## CloudWatch Metric Mathで可用性SLIを作る

CloudWatch Metric Mathは、グラフに追加したメトリクスの行IDを使って計算式を書く機能です。
たとえば、5系エラー数の行IDが `m1`、リクエスト総数の行IDが `m2` の場合、可用性SLIは以下の式で表せます。

```text
e1 = (1 - m1 / m2) * 100
```

この式は「全リクエストのうち、5系エラーではなかった割合」をパーセントで表示します。

### 画面での設定手順

1. CloudWatchで対象のALBメトリクスを開きます。
2. `HTTPCode_Target_5XX_Count` を追加し、統計を `Sum` にします。
3. `RequestCount` を追加し、統計を `Sum` にします。
4. 追加された各行のIDを確認します。多くの場合は `m1`、`m2` ですが、画面の状態によって `m3`、`m4` などになることがあります。
5. **数式を追加** から式を作成し、画面に表示されているIDに合わせて `(1 - m1 / m2) * 100` を入力します。
6. 数式のラベルを `可用性SLI(%)` など、あとから見て意味が分かる名前に変更します。
7. グラフを読みやすくするため、必要に応じて元の `m1`、`m2` を非表示にし、式 `e1` を中心に表示します。

ポイント:

- `m1` や `m2` は固定の名前ではなく、CloudWatch画面上で自動的に付く行IDです。
- 式のIDは、必ず自分の画面に表示されているIDに合わせます。
- 5系エラー数とリクエスト数は、同じ期間・同じ統計で比較します。ここではどちらも `Sum` を使います。
- 可用性ではなくエラー率を見たい場合は、`m1 / m2 * 100` とします。
- エラーバジェット残量を見たい場合は、SLO目標から許容エラー率を決め、実際のエラー率との差分を計算します。たとえば可用性SLOが99.5%なら、許容エラー率は0.5%です。

## 模擬インシデント

CPU負荷を発生させます。

```bash
bash scripts/08_incident_drill.sh
```

## 確認ポイント

- CloudWatch DashboardでCPU使用率が上がる
- Alarm状態が変わる
- Systems Manager Run Commandの実行履歴が残る
- タイムラインを記録できる

タイムライン例:

```text
[14:03] CPU負荷演習を開始
[14:05] CPU使用率上昇をCloudWatchで確認
[14:08] アラーム状態を確認
[14:11] 原因がstress-ngであることを確認
[14:13] 停止コマンドを実行
[14:15] CPU使用率が回復
```

## 停止コマンド

必要に応じて以下を実行します。

```bash
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --query "Stacks[0].Outputs[?OutputKey=='AppInstanceId'].OutputValue" \
  --output text)

aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["sudo killall stress-ng || true"]' \
  --region ap-northeast-1
```

## 次へ

[08 ポストモーテム](08-postmortem.md) に進みます。
