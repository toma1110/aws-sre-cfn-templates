# 01 サンプルアプリをデプロイ

対応講義: `s3-l5` ハンズオン: サンプルWebアプリを本番想定でデプロイ

## 目的

CloudFormationで、監視対象になる小さなWebアプリ環境を作ります。

作成される主なリソース:

- VPC
- ALB
- EC2
- RDS
- CloudWatch Logsロググループ
- CloudWatch Agent設定
- X-Ray送信用設定

## 手順

```bash
export AWS_REGION=ap-northeast-1
export KEY_NAME="your-key-pair-name"
bash scripts/01_deploy_base.sh
```

パスワード入力を求められたら、RDS用の一時パスワードを入力します。値は第三者に共有せず、IssueやGitなど公開される場所に記録しないでください。

## 期待結果

CloudFormation Outputsに以下が表示されます。

- `ALBEndpoint`
- `ALBFullName`
- `AppInstanceId`
- `RDSEndpoint`

アプリ確認:

```bash
ALB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name sre-handson-base \
  --region ap-northeast-1 \
  --query "Stacks[0].Outputs[?OutputKey=='ALBEndpoint'].OutputValue" \
  --output text)

curl "$ALB_ENDPOINT/"
curl "$ALB_ENDPOINT/api/data"
curl "$ALB_ENDPOINT/api/process"
```

`/api/data` と `/api/process` は意図的に一定確率で5系のエラーを返します。これは後続のログ、メトリクス、アラーム演習で使うための正常な教材挙動です。

## 次へ

```bash
bash scripts/02_generate_traffic.sh
```

その後、[02 ダッシュボード](02-dashboard.md) に進みます。

## 後片付け

作業を終える場合は [後片付け](99-cleanup.md) を実行してください。
