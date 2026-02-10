# 運用手順書

## 目次

- [日常の開発フロー](#日常の開発フロー)
- [機能開発の進め方（TDD）](#機能開発の進め方tdd)
- [ブランチ運用](#ブランチ運用)
- [CI パイプライン](#ci-パイプライン)
- [テスト戦略](#テスト戦略)
- [DB 操作](#db-操作)
- [デモ環境の準備](#デモ環境の準備)
- [トラブルシューティング](#トラブルシューティング)

---

## 日常の開発フロー

### 1. 小さな修正・バグフィックス

リポジトリオーナーは main に直接 push 可能。

```bash
# コード修正
vim app/...

# テスト + Lint
bundle exec rspec
bin/rubocop

# コミット & push
git add -p
git commit -m "Fix ..."
git push origin main
```

### 2. 機能開発（PR経由）

外部コントリビューターや大きめの変更はブランチを切ってPR。

```bash
# ブランチ作成
git checkout -b feature/xxx

# 開発 → テスト → コミット（繰り返し）
bundle exec rspec
git commit ...

# push & PR作成
git push -u origin feature/xxx
gh pr create --title "Add xxx" --body "..."
```

CI（lint, scan_ruby, scan_js, test, e2e）が全てパスしないとマージ不可。

---

## 機能開発の進め方（TDD）

CLAUDE.md に定義された TDD フローに従う。

```
1. 計画書作成     docs/plans/xxx.md にチェックリスト付きで書く
2. レビュー       ユーザーに計画書を確認してもらう
3. テスト作成     RSpec で先にテストを書く（RED）
4. 実装           テストが通る最小限のコードを書く（GREEN）
5. リファクタリング  テストを維持しつつ改善
6. 計画書更新     チェックリストを [x] に更新
7. コミット & push
```

### 計画書のテンプレート

```markdown
# 機能名

## 概要
何を実装するか

## 画面構成
- 一覧画面: GET /xxx
- 詳細画面: GET /xxx/:id

## DB変更
- テーブル追加: xxx
- カラム追加: yyy

## 成果物チェックリスト
- [ ] モデル
- [ ] コントローラー
- [ ] ビュー
- [ ] テスト
- [ ] マイグレーション
```

---

## ブランチ運用

### ブランチ保護ルール（main）

| ルール | 設定 |
|--------|------|
| 必須 CI チェック | lint, scan_ruby, scan_js, test, e2e |
| ステータスチェック最新性 | 必須（strict） |
| admin バイパス | 許可（オーナーは直接 push 可） |
| force push | 禁止 |
| ブランチ削除 | 禁止 |

### ブランチ命名規則

| 用途 | パターン | 例 |
|------|---------|-----|
| 新機能 | `feature/xxx` | `feature/teams-notification` |
| バグ修正 | `fix/xxx` | `fix/routing-error` |
| リファクタリング | `refactor/xxx` | `refactor/extract-service` |
| ドキュメント | `docs/xxx` | `docs/api-guide` |

---

## CI パイプライン

push / PR 時に GitHub Actions で自動実行される。

```
┌─────────┐  ┌──────────┐  ┌─────────┐
│  lint   │  │ scan_ruby│  │ scan_js │  ← 並列実行
└────┬────┘  └────┬─────┘  └────┬────┘
     │            │             │
     └────────────┼─────────────┘
                  ▼
           ┌──────────┐
           │   test   │  ← RSpec (151テスト)
           └────┬─────┘
                ▼
           ┌──────────┐
           │   e2e    │  ← Playwright (54テスト)
           └──────────┘
```

| ジョブ | 内容 | 所要時間 |
|--------|------|---------|
| lint | Rubocop によるコードスタイルチェック | ~18s |
| scan_ruby | Brakeman（セキュリティ）+ bundler-audit（脆弱性） | ~14s |
| scan_js | importmap audit（JS依存関係の脆弱性） | ~14s |
| test | RSpec ユニット/リクエストテスト | ~37s |
| e2e | Playwright ブラウザテスト（test 完了後に実行） | ~2m30s |

### CI が失敗した場合

```bash
# ローカルで再現
bin/rubocop              # lint 失敗時
bundle exec rspec        # test 失敗時
npx playwright test      # e2e 失敗時

# E2E の詳細レポートを確認
npx playwright show-report
```

GitHub Actions の Artifacts から `playwright-report` をダウンロードして詳細確認も可能。

---

## テスト戦略

### テストの種類と使い分け

| 種類 | ツール | 対象 | 実行タイミング |
|------|--------|------|---------------|
| モデルスペック | RSpec | バリデーション、スコープ、メソッド | 常時 |
| リクエストスペック | RSpec | コントローラーのHTTPレスポンス | 常時 |
| E2E スモーク | Playwright | 全画面の200 OK + ルーティングエラー検出 | 画面変更時 |
| E2E ナビゲーション | Playwright | サイドバーリンクの遷移確認 | 画面変更時 |
| E2E CRUD | Playwright | 作成・編集・削除のフロー | 機能変更時 |
| E2E 権限 | Playwright | viewer ロールのアクセス制限 | 権限変更時 |

### テストファイルの場所

```
spec/
├── models/          # モデルスペック
├── requests/        # リクエストスペック
├── factories/       # FactoryBot ファクトリ
└── support/         # ヘルパー

e2e/
├── helpers/auth.ts  # ログインヘルパー
├── smoke.spec.ts    # スモークテスト（25テスト）
├── navigation.spec.ts  # ナビゲーション（10テスト）
├── crud.spec.ts     # CRUD操作（5テスト）
└── viewer-access.spec.ts  # 権限テスト（14テスト）
```

### E2E テスト初回セットアップ

```bash
npm install
npx playwright install chromium
RAILS_ENV=test bin/rails assets:precompile
```

### E2E テストのデバッグ

```bash
# UI モードで対話的にデバッグ
npx playwright test --ui

# 特定のテストだけ実行
npx playwright test e2e/smoke.spec.ts

# スクリーンショット付きレポート
npx playwright test --reporter=html
npx playwright show-report
```

---

## DB 操作

### よく使うコマンド

```bash
# 開発DB: 作成 + マイグレーション + シードデータ
rails db:create db:migrate db:seed

# 開発DB: リセット（全データ削除 → 再作成 → シード投入）
rails db:reset

# マイグレーション作成
rails generate migration AddXxxToYyy

# マイグレーション状態確認
rails db:migrate:status

# テストDB: スキーマのみ（シードなし、RSpec用）
RAILS_ENV=test rails db:drop db:create db:schema:load

# テストDB: シード付き（E2E用、通常は Playwright が自動実行）
RAILS_ENV=test rails db:prepare db:seed
```

### シードデータの内容

`rails db:seed` で投入されるデモデータ:

| データ | 件数 | 説明 |
|--------|------|------|
| ユーザー | 15名 | 情シス3名、営業4名、管理部3名、企画3名、役員2名 |
| SaaS | 30件 | 一般IT 14件、不動産管理 11件、バックオフィス 5件 |
| アカウント | ~130件 | 全社共通 + 部門別のSaaS割り当て |
| タスクプリセット | 3件 | 退職処理、入社処理、異動処理 |
| タスク | 2件 | 完了済み1件、進行中1件 |
| サーベイ | 2件 | 完了済み1件、配信中1件 |
| 承認申請 | 4件 | 承認済み2件、却下1件、保留1件 |
| 操作ログ | ~20件 | 各種操作のサンプル |

### デモ用アカウント

| 名前 | メール | ロール | 用途 |
|------|--------|--------|------|
| 管理者 太郎 | admin@example.com | admin | 管理者操作のデモ |
| 鈴木 花子 | suzuki@example.com | manager | マネージャー操作のデモ |
| 高橋 大輔 | takahashi@example.com | viewer | 一般ユーザーのデモ |

---

## デモ環境の準備

プレゼンやレビュー前にクリーンなデモ環境を用意する手順。

```bash
# 1. 開発DBをリセット（クリーンなシードデータで開始）
rails db:reset

# 2. サーバー起動
bin/dev

# 3. ブラウザでアクセス
# http://localhost:3000

# 4. dev_login フォームで admin@example.com でログイン
```

### デモシナリオ例

1. **ダッシュボード** → 全体概況の説明
2. **SaaS台帳** → 30件のSaaS一覧、検索・フィルタ、詳細表示
3. **アカウント管理** → 130件のアカウント、SaaS別/ユーザー別フィルタ
4. **メンバー** → 15名の一覧、個人のSaaS保有状況
5. **サーベイ** → 配信中サーベイの回答状況
6. **タスク管理** → 退職処理タスクのチェックリスト進捗
7. **申請・承認** → 新規申請 → 承認のフロー実演
8. **操作ログ** → 変更差分の確認（コンプライアンス訴求）
9. **バッチ管理** → Entra ID同期の説明

---

## トラブルシューティング

### PostgreSQL が起動しない（WSL）

```bash
sudo service postgresql start
# ポートが 5433 の場合は config/database.yml を確認
```

### RSpec でテストが大量に失敗する

テストDBにシードデータが残っている可能性あり（E2Eテスト実行後など）。

```bash
# テストDBをクリーンに再構築
RAILS_ENV=test rails db:drop db:create db:schema:load
bundle exec rspec
```

### E2E テストが全て失敗する

```bash
# アセットのプリコンパイルを確認
RAILS_ENV=test rails assets:precompile

# テストDBにシードデータがあるか確認
RAILS_ENV=test rails runner "puts User.count"
# 0 の場合はシードが必要（Playwright の webServer が自動実行するので通常は不要）
```

### Playwright のブラウザが見つからない

```bash
npx playwright install chromium
```

### `bin/dev` でサーバーが起動しない

```bash
# Procfile.dev を確認
cat Procfile.dev

# 直接起動して確認
rails server
```

### マイグレーションエラー

```bash
# 現在のマイグレーション状態を確認
rails db:migrate:status

# pending があれば実行
rails db:migrate
```
