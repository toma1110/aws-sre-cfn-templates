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
