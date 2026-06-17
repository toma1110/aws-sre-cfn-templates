# 02 ダッシュボード

対応講義: `s4-l4` ハンズオン: ダッシュボードを作る

## 目的

EC2、ALB、RDS、アプリの状態をCloudWatch Dashboardで一画面にまとめます。

## 事前準備

[01 サンプルアプリをデプロイ](01-deploy-sample-app.md) が完了していること。

メトリクスを動かすため、先にトラフィックを流します。

```bash
bash scripts/02_generate_traffic.sh
```

## 手順

```bash
bash scripts/03_deploy_dashboard.sh
```

## 期待結果

CloudFormation Outputsに `DashboardURL` が表示されます。

ダッシュボードで見るポイント:

- ALB RequestCount
- ALB 5系のエラー
- ALB TargetResponseTime
- EC2 CPUUtilization
- RDS CPUUtilization

## 次へ

[03 カスタムメトリクス](03-custom-metrics.md) に進みます。
