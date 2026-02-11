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

## Docker 環境構築

ローカルの Ruby / PostgreSQL を使わずに Docker だけでアプリを起動できます。

### Docker Compose（推奨）

```bash
# 起動（PostgreSQL + Rails アプリ）
docker compose up -d

# ログ確認
docker compose logs -f web

# 停止 & クリーンアップ
docker compose down -v
```

http://localhost:8080 でアクセス可能（PostgreSQL も自動起動）。

### 手動ビルド & 起動

```bash
# ビルド（WSL 環境は --network=host が必要）
docker build --network=host -t dxceco-poc:latest .

# 起動（ローカル PostgreSQL を使う場合）
docker run --rm --network=host \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL="postgres://<DBユーザー>:<パスワード>@localhost:5433/dxceco_poc_production" \
  -e DXCECO_POC_DATABASE_PASSWORD=<パスワード> \
  -e DB_HOST=localhost \
  -e DB_USERNAME=<DBユーザー> \
  -e PGPORT=5433 \
  -e RAILS_ENV=production \
  -e SOLID_QUEUE_IN_PUMA=true \
  -e APP_URL=http://localhost:8080 \
  -e TARGET_PORT=3080 \
  -e HTTP_PORT=8080 \
  dxceco-poc:latest
```

### Azure デプロイ

Azure Container Apps へのデプロイ手順は **[インフラ構成](infra/インフラ構成.md)** を参照。

## 開発運用フロー

詳細は **[運用手順書](docs/operations.md)** を参照。

### テスト使い分け

| テスト | 実行タイミング | 所要時間 |
|--------|---------------|---------|
| `bundle exec rspec` | コード変更のたび（常時） | 約3秒 |
| `bin/rubocop` | コミット前 | 約5秒 |
| `npx playwright test` | 画面変更時・リリース前 | 約1.5分 |

### CI（GitHub Actions）

push / PR 時に自動実行（全パスしないと main にマージ不可）:

| ジョブ | 内容 | 所要時間 |
|--------|------|---------|
| lint | Rubocop | ~18s |
| scan_ruby | Brakeman + bundler-audit | ~14s |
| scan_js | importmap audit | ~14s |
| test | RSpec (194テスト) | ~37s |
| e2e | Playwright (54テスト) | ~2m30s |

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

## ドキュメント

- **[ユーザー運用ガイド](docs/user-guide.md)** - 管理者・マネージャー・一般ユーザー向けの操作手順
- **[開発運用手順書](docs/operations.md)** - 開発フロー、ブランチ運用、CI、テスト戦略、DB操作
- **[環境変数・外部サービス接続ガイド](docs/environment-setup.md)** - Entra ID SSO、Teams通知、DB設定
- **[機能一覧](docs/features/)** - 各画面・機能の詳細ドキュメント

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
├── features/        # 機能別ドキュメント（01_dashboard.md 〜 11_csv_import.md）
├── plans/           # 実装計画書
├── operations.md    # 運用手順書
└── *.md             # 調査レポート・設計書

e2e/                 # Playwright E2Eテスト
spec/                # RSpecテスト
```
