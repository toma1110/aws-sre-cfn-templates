# 09 コストアラート

対応講義: `s10-l4` ハンズオン: コストアラートを設定する

## 目的

AWS BudgetsとCost Anomaly Detectionで、想定外の料金に早く気づく仕組みを作ります。

## 手順

```bash
export NOTIFICATION_EMAIL="your@example.com"
export MONTHLY_BUDGET_AMOUNT=20
export ANOMALY_THRESHOLD_AMOUNT=5
bash scripts/09_deploy_cost_alerts.sh
```

このスタックは `us-east-1` に作成します。

## 期待結果

CloudFormation Outputsに以下が表示されます。

- `SNSTopicArn`
- `BudgetName`
- `CostExplorerURL`
- `AnomalyDetectionURL`

## 確認ポイント

- SNS確認メールを承認する
- Budgetsに月次予算が作られている
- Cost Anomaly Detectionの通知設定が作られている

## 注意

Budgetsやコスト異常検知は、実際の利用料金や反映タイミングに依存します。設定直後にすぐ通知が届かない場合があります。

## 後片付け

[後片付け](99-cleanup.md) を実行してください。
