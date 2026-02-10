# SaaS管理ツール POC (dxeco-poc)

組織内で利用しているSaaS（約260件）のアカウントを一元管理するWebアプリケーション。
DXECO（年204万円）の代替として自社開発で現場課題を解決できることを実証するPOC。

## 技術スタック

- Ruby 3.3.2 / Rails 8.1.2
- PostgreSQL
- Bootstrap 5（CDN + importmap）
- OmniAuth + Entra ID（OIDC認証）
- Hotwire（Turbo, Stimulus）
- RSpec + FactoryBot

## 開発環境構築

### 前提条件

- Ruby 3.3.2（rbenv推奨）
- PostgreSQL 14+
- Git

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/JFujimoto2/dxeco-poc.git
cd dxeco-poc

# Gemインストール
bundle install

# 環境変数ファイルを作成
cp .env.example .env
# 必要に応じて .env を編集（Entra ID設定等）

# PostgreSQL起動（WSLの場合）
sudo service postgresql start

# データベース作成・マイグレーション・初期データ投入
rails db:create db:migrate db:seed

# サーバー起動
bin/dev
```

http://localhost:3000 にアクセスし、開発用ログインフォームからログイン。

### 環境変数（.env）

| 変数 | 説明 | 必須 |
|------|------|------|
| `ENTRA_CLIENT_ID` | Entra IDのクライアントID | SSO利用時のみ |
| `ENTRA_CLIENT_SECRET` | Entra IDのクライアントシークレット | SSO利用時のみ |
| `ENTRA_TENANT_ID` | Entra IDのテナントID | SSO利用時のみ |
| `APP_URL` | アプリのURL（デフォルト: http://localhost:3000） | SSO利用時のみ |

`.env` に `ENTRA_CLIENT_ID` を設定するとSSO認証が有効になります。
未設定の場合は開発用ログインフォームが表示されます。

### PostgreSQLのポート

WSL環境ではポート5433で起動する場合があります。`config/database.yml` の `port` 設定を確認してください。

### テスト実行

```bash
# ユニットテスト / リクエストスペック（約3秒）
bundle exec rspec

# E2Eテスト（約1.5分、Railsサーバー自動起動）
npx playwright test

# E2Eテスト UIモード（デバッグ用）
npx playwright test --ui
```

## 開発運用フロー

### 日常の開発サイクル

```
コード変更 → RSpec → コミット
```

```bash
# 1. コード変更後（毎回）
bundle exec rspec

# 2. Lint + セキュリティチェック
bin/rubocop

# 3. 問題なければコミット
```

### 画面・ルーティング変更時

```
コード変更 → RSpec → E2E → コミット
```

```bash
# 1. ユニットテスト
bundle exec rspec

# 2. 全画面のブラウザテスト
npx playwright test

# 3. 問題なければコミット
```

### テスト使い分け

| テスト | 実行タイミング | 所要時間 |
|--------|---------------|---------|
| `bundle exec rspec` | コード変更のたび（常時） | 約3秒 |
| `bin/rubocop` | コミット前 | 約5秒 |
| `npx playwright test` | 画面変更時・リリース前 | 約1.5分 |

### CI（GitHub Actions）

プッシュ時に自動実行:
- Rubocop（lint）
- Brakeman（セキュリティ）
- RSpec（ユニット/リクエスト）

### E2Eテスト初回セットアップ

```bash
npm install
npx playwright install chromium
RAILS_ENV=test bin/rails assets:precompile
```

### 初期データ

`rails db:seed` で以下のデモデータが投入されます:

- ユーザー 5名（admin, manager, viewer）
- SaaS 12件（一般 7件 + 不動産管理 5件）
- アカウント 約20件

## ディレクトリ構成

```
app/
├── controllers/     # コントローラー
├── models/          # モデル
├── views/           # ビュー
│   └── shared/      # 共通パーシャル（sidebar, flash等）
├── jobs/            # バックグラウンドジョブ
└── services/        # 外部API連携

docs/
├── plans/           # 機能別の実装計画書
└── *.md             # 調査レポート・設計書

spec/                # RSpecテスト
```
