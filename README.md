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
bundle exec rspec
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
