# Graph API メール送信

## 概要

ActionMailer の delivery method を SMTP から Microsoft Graph API (`/v1.0/users/{sender}/sendMail`) に変更する。
Security Defaults が有効なテナントでは SMTP AUTH が使えないため、Graph API で送信する。

## 前提条件

- [ ] Entra ID アプリに `Mail.Send` アプリケーション権限を追加 + Admin Consent

## 実装計画

### 新規ファイル
- `lib/graph_api_delivery.rb` — カスタム delivery method クラス
- `config/initializers/graph_api_delivery.rb` — delivery method 登録
- `spec/lib/graph_api_delivery_spec.rb` — テスト

### 変更ファイル
- `config/environments/production.rb` — SMTP → Graph API に変更
- `config/environments/development.rb` — ENTRA_CLIENT_ID があれば Graph API、なければ letter_opener_web

### 実装内容

1. `GraphApiDelivery` クラスに `initialize(settings)` と `deliver!(mail)` を実装
2. `EntraClient.fetch_app_token`（client_credentials フロー）でトークン取得
3. Graph API `/v1.0/users/{sender}/sendMail` に POST
4. 既存の3つの Mailer（Survey, Task, ApprovalRequest）は変更不要

### テスト方針
- WebMock で Graph API 呼び出しを stub
- to/cc/HTML本文/エラーハンドリングのケースをカバー
- 既存の Mailer スペックは変更不要（test 環境は `:test` delivery method のまま）

## チェックリスト

- [ ] Entra ID に Mail.Send 権限追加
- [ ] テスト作成（RED）
- [ ] 実装（GREEN）
- [ ] delivery method 登録 + 環境設定変更
- [ ] rubocop / brakeman パス
- [ ] 全テストパス
- [ ] ローカルでメール送信テスト
