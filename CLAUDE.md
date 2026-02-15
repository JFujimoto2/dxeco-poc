# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

SaaS（約260件）のアカウントを一元管理するWebアプリケーション（POC）。
DXECO（年204万円）の代替として自社開発の実証。

**技術スタック:** Ruby 3.3.2 / Rails 8.1.2 / PostgreSQL / Bootstrap 5 / Entra ID SSO (OIDC) / Hotwire / Solid Queue

## コマンド

```bash
bin/dev                              # サーバー起動（localhost:3000）
bundle exec rspec                    # RSpec全テスト実行
bundle exec rspec spec/models/user_spec.rb        # 単一ファイル実行
bundle exec rspec spec/models/user_spec.rb:15     # 特定行のテスト実行
bin/rubocop                          # Rubocop lint
bin/rubocop -a                       # Rubocop 自動修正
bin/brakeman --no-pager              # Brakeman セキュリティスキャン
npx playwright test                  # E2Eテスト（Playwright）
npx playwright test e2e/saas.spec.ts # 単一E2Eファイル実行
rails db:create db:migrate db:seed   # DB初期化
```

## 開発ルール

### ブランチ運用
- `main`: 開発統合ブランチ（PRマージのみ、直接push不可）
- `prod`: 本番リリースブランチ（PRマージで Azure へ自動デプロイ）
- 作業ブランチ → PR → `main` → PR → `prod` → 自動デプロイ

### 機能開発フロー（TDD必須）
1. **計画書作成** → `docs/plans/` に `.md` を作成、ユーザーレビュー後に着手
2. **テスト作成（RED）** → 先にRSpecテストを書き、失敗を確認
3. **実装（GREEN）** → テストが通る最小限のコード（モデル→コントローラー→ビュー）
4. **リファクタリング** → テスト維持しつつ改善
5. **ドキュメント更新** → `docs/plans/` チェックリスト更新 + `docs/features/` 更新
6. **コミット & PR** → feature ブランチから `main` へ PR を作成

### コーディング規約
- 日本語UIだがコード（変数名・メソッド名）は英語
- enumは文字列型を使用（`enum :role, { viewer: "viewer", admin: "admin" }`）
- N+1クエリ注意（`includes` / `preload` を使う）
- Rubocop: `rubocop-rails-omakase` スタイル準拠

## CI/CD（GitHub Actions）

### CI（`ci.yml` — main への push/PR 時）
5ジョブ: `lint`(Rubocop) / `scan_ruby`(Brakeman+bundler-audit) / `scan_js`(importmap audit) / `test`(RSpec) / `e2e`(Playwright、testジョブ完了後)

### CD（`deploy.yml` — prod への push 時）
Docker ビルド → ACR プッシュ → Azure Container Apps 更新（自動デプロイ）

## アーキテクチャ

### 認証・認可
- `ApplicationController` で `before_action :require_login` — 全リクエストにログイン必須
- `session[:user_id]` ベースのセッション認証（`current_user` ヘルパー）
- `Current` (ActiveSupport::CurrentAttributes) に `user` と `ip_address` を保持
- ロール: `admin` / `manager` / `viewer` — `require_admin` で管理者制限
- 開発環境: `ENTRA_CLIENT_ID` 未設定時は `dev_login` フォームが表示される
- テスト: `login_as(user)` ヘルパー（`spec/support/login_helper.rb`）で `dev_login_path` にPOST

### 操作ログ（Auditable concern）
- `app/models/concerns/auditable.rb` — `include Auditable` するとcreate/update/destroyが自動記録
- `AuditLog` に `user`（Current.user）, `action`, `resource_type/id`, `changes_data`(JSONB), `ip_address` を保存
- User, Saas 等の主要モデルに適用済み

### 外部サービス連携
- `TeamsNotifier` — Teams Webhook通知（`TEAMS_WEBHOOK_URL` / `TEAMS_WEBHOOK_SURVEY_URL`）
- `EntraClient` — Entra ID (Microsoft Graph API) ユーザー同期
- テスト時はTeams Webhookを `nil` にstub（`spec/support/teams_notifier.rb`）

### ドメインモデル（主要テーブル）
- `User` → `SaasAccount` (多:多) → `Saas` → `SaasContract` (1:1)
- `Survey` → `SurveyResponse`（利用状況サーベイ）
- `Task` → `TaskItem`（退職者対応等のタスク）/ `TaskPreset` → `TaskPresetItem`（テンプレート）
- `ApprovalRequest`（SaaS追加/削除の承認ワークフロー）
- `BatchExecutionLog`（Entra同期・退職者検出のバッチ実行記録）

### バックグラウンドジョブ
- Solid Queue（`solid_queue` gem）
- `EntraUserSyncJob` — Entra IDからユーザー同期
- `RetiredAccountDetectionJob` — 退職者アカウント検出

### メーラー
- `TaskMailer` / `ApprovalRequestMailer` / `SurveyMailer`
- 開発環境: `letter_opener_web`（`/letter_opener` でプレビュー）

### フロントエンド
- Importmap + Hotwire（Turbo, Stimulus）
- Bootstrap 5
- 共通パーシャル: `app/views/shared/`（sidebar, flash等）

## テスト

- RSpec + FactoryBot（`spec/factories/`）
- WebMock で外部API呼び出しをstub
- リクエストスペック（`spec/requests/`）がメイン、モデルスペック（`spec/models/`）、メーラースペック（`spec/mailers/`）
- E2E: Playwright（`e2e/` ディレクトリ）
