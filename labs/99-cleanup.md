# 99 後片付け

## 目的

ハンズオンで作成したAWSリソースを削除し、不要な課金を止めます。

## 手順

```bash
bash scripts/99_cleanup.sh
```

確認メッセージが表示されたら、削除対象を読んでから `delete-sre-handson` と入力します。

## 削除順

1. `sre-handson-cost-alerts`
2. `sre-handson-alarms`
3. `sre-handson-log-filter`
4. `sre-handson-custom-metrics`
5. `sre-handson-dashboard`
6. `sre-handson-base`

## 削除確認

```bash
bash scripts/90_verify.sh
```

CloudFormationコンソールでも、対象スタックが `DELETE_COMPLETE` または存在しない状態になっていることを確認します。

## 残る可能性があるもの

- メールボックス内の通知メール
- CloudWatchの一部メトリクス履歴
- Cost ExplorerやBudgetsの反映履歴

これらは通常、追加料金の主因ではありません。課金対象の中心はEC2、RDS、ALBなどの実リソースです。
