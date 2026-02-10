# CLAUDE.md - SaaS管理ツール POC

## プロジェクト概要
組織内で利用している各SaaS（約260件）のアカウント（ID）を一元管理するWebアプリケーション。
DXECO（年204万円）の代替として自社開発で現場課題を解決できることを実証するPOC。

## 技術スタック
- Ruby 3.3.2 / Rails 8.1.2
- PostgreSQL
- Bootstrap 5（importmap経由）
- OmniAuth + Entra ID（OIDC認証）
- Importmap + Hotwire（Turbo, Stimulus）
- Solid Queue（バックグラウンドジョブ）

## 開発ルール

### 1. 機能開発フロー（TDD）
**必ずテスト駆動開発（TDD）で進めること:**

1. **計画書作成** (`docs/plans/` に `.md` ファイルを作成)
   - 実装する機能の要件・画面構成・DB変更・ルーティングを明記
   - 成果物チェックリスト（`- [ ]` 形式）を含める
   - ユーザーにレビューしてもらってから実装に着手
2. **テスト作成（RED）** - 先にRSpecテストを書く
   - モデルスペック: `spec/models/`
   - リクエストスペック: `spec/requests/`
   - 必要に応じてシステムスペック: `spec/system/`
   - テストが失敗（RED）することを確認
3. **実装（GREEN）** - テストが通る最小限のコードを書く
   - モデル → コントローラー → ビュー の順
   - テストが全てパス（GREEN）することを確認
4. **リファクタリング（REFACTOR）** - テストを維持しつつコードを改善
5. **計画書更新** (コミット前に必ず実施)
   - チェックリストを `- [x]` に更新
   - 実装時の補足事項があれば追記
6. **コミット & push**

### 2. テスト（TDD原則）
- テストフレームワーク: **RSpec**
- ファクトリ: **FactoryBot**
- テスト実行: `bundle exec rspec`
- **テストを先に書き、失敗を確認してから実装に入る**（RED → GREEN → REFACTOR）
- 新しいモデル・コントローラーを作成する際は、必ず先にスペックを書く
- CIで全テストがパスすることを確認してからマージ
- CI: Rubocop（lint） + Brakeman（セキュリティ） + RSpec（テスト）

### 3. ディレクトリ構成
```
app/
├── controllers/
│   ├── admin/              # admin専用（バッチ管理・操作ログ）
│   └── ...                 # 一般コントローラー
├── models/
├── jobs/                   # Active Job（Entra ID同期等）
├── services/               # 外部API連携（EntraClient, TeamsNotifier）
└── views/
    ├── layouts/
    ├── shared/             # 共通パーシャル（sidebar, flash等）
    └── admin/

docs/
├── plans/                  # 機能別の実装計画書
├── インフラ構成案.md
├── デクセコ_調査レポート_.md
├── バッチ処理設計.md
├── 自社開発_タスク_機能一覧.md
├── 認証方式の実装方針.md
└── 運用ルール.md

spec/
├── models/
├── requests/
├── system/
├── factories/
├── support/
└── rails_helper.rb
```

### 4. コーディング規約
- ロケール: 日本語UIだが、コード（変数名・メソッド名）は英語
- enumは文字列型を使用（integer enumは避ける）
- N+1クエリに注意（`includes` / `preload` を使う）
- Strong Parametersを必ず使う

### 5. 認証・権限
- Entra ID SSO (OIDC) でログイン
- ロール: `admin` / `manager` / `viewer`
- 開発環境ではSSO未設定でも動作するようスキップ可能にする

### 6. コマンド
```bash
# サーバー起動
bin/dev

# テスト実行
bundle exec rspec

# DB操作
rails db:create db:migrate db:seed

# Lint
bin/rubocop
```

### 7. POCフェーズ
| フェーズ | 内容 |
|---------|------|
| 1. 基盤 | Rails + Entra ID認証 + 権限管理 |
| 2. 台帳 | SaaS台帳・契約・アカウント・メンバー管理 |
| 3. 差別化 | サーベイ・タスク管理・申請承認・退職者検出 |
| 4. 仕上げ | Teams通知・操作ログ・デモデータ・デプロイ |
