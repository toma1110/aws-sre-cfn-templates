# 00 環境準備

対応講義: `s1-l4` AWSアカウント・環境セットアップ

## 目的

ハンズオンを安全に始めるために、CloudShell、リージョン、AWS CLI接続、EC2キーペア、料金注意を確認します。

## 前提

- AWSアカウントにログインできること
- CloudShellを開けること
- 東京リージョン `ap-northeast-1` を使うこと
- EC2キーペアを用意していること

## 手順

```bash
export AWS_REGION=ap-northeast-1
export KEY_NAME="your-key-pair-name"
bash scripts/00_preflight.sh
```

## 期待結果

- 実行アカウントとプリンシパルが表示される
- リージョンが `ap-northeast-1` と表示される
- CloudFormationテンプレートがすべて `OK` になる
- `KEY_NAME` が存在する場合は確認成功する

## 次へ

[01 サンプルアプリをデプロイ](01-deploy-sample-app.md) に進みます。

## 注意

この後の手順ではEC2、RDS、ALBなど料金が発生するリソースを作成します。作業後は [後片付け](99-cleanup.md) を必ず実行してください。
