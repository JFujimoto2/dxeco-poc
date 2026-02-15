# 運用手順書

## 目次

- [日常の開発フロー](#日常の開発フロー)
- [機能開発の進め方（TDD）](#機能開発の進め方tdd)
- [ブランチ運用](#ブランチ運用)
- [CI パイプライン](#ci-パイプライン)
- [テスト戦略](#テスト戦略)
- [メール通知（開発環境）](#メール通知開発環境)
- [Entra ID セットアップ（SSO + ユーザー同期）](#entra-id-セットアップsso--ユーザー同期)
- [DB 操作](#db-操作)
- [デモ環境の準備](#デモ環境の準備)
- [トラブルシューティング](#トラブルシューティング)

---

## 日常の開発フロー

すべての変更は **PR 経由** で `main` にマージする（直接 push 不可）。

```
feature/xxx ──PR──▶ main ──PR──▶ prod ──自動デプロイ──▶ Azure
```

### 1. 開発（feature → main）

```bash
# ブランチ作成
git checkout -b feature/xxx

# 開発 → テスト → コミット（繰り返し）
bundle exec rspec
bin/rubocop
git commit ...

# push & PR作成
git push -u origin feature/xxx
gh pr create --title "Add xxx" --body "..."
```

CI（lint, scan_ruby, scan_js, test, e2e）が全てパスしないとマージ不可。

### 2. デプロイ（main → prod）

`main` の変更を本番に反映する場合、`main` → `prod` への PR を作成してマージする。

```bash
# main → prod の PR を作成
gh pr create --base prod --head main --title "Release: xxx"
```

`prod` へのマージで GitHub Actions が自動実行:
1. Docker イメージをビルド
2. Azure Container Registry (ACR) にプッシュ
3. Azure Container Apps を更新

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

### ブランチ構成

| ブランチ | 用途 | デプロイ |
|----------|------|---------|
| `main` | 開発統合ブランチ | - |
| `prod` | 本番リリースブランチ | マージ時に Azure へ自動デプロイ |
| `feature/*` 等 | 作業ブランチ | - |

### ブランチ保護ルール（main / prod 共通）

| ルール | 設定 |
|--------|------|
| PR マージ必須 | 直接 push 不可 |
| 必須 CI チェック | lint, scan_ruby, scan_js, test, e2e |
| ステータスチェック最新性 | 必須（strict） |
| 承認レビュー | 0人（一人開発のため） |
| admin バイパス | 許可（オーナーは緊急時のみ） |
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

## CI/CD パイプライン

### CI（`.github/workflows/ci.yml`）

`main` への push / PR 時に自動実行。

```
┌─────────┐  ┌──────────┐  ┌─────────┐
│  lint   │  │ scan_ruby│  │ scan_js │  ← 並列実行
└────┬────┘  └────┬─────┘  └────┬────┘
     │            │             │
     └────────────┼─────────────┘
                  ▼
           ┌──────────┐
           │   test   │  ← RSpec
           └────┬─────┘
                ▼
           ┌──────────┐
           │   e2e    │  ← Playwright
           └──────────┘
```

| ジョブ | 内容 | 所要時間 |
|--------|------|---------|
| lint | Rubocop によるコードスタイルチェック | ~18s |
| scan_ruby | Brakeman（セキュリティ）+ bundler-audit（脆弱性） | ~14s |
| scan_js | importmap audit（JS依存関係の脆弱性） | ~14s |
| test | RSpec ユニット/リクエストテスト | ~37s |
| e2e | Playwright ブラウザテスト（test 完了後に実行） | ~2m30s |

### CD（`.github/workflows/deploy.yml`）

`prod` への push 時に自動実行。

```
┌───────────────┐     ┌───────────────┐     ┌──────────────────┐
│ Azure ログイン │ ──▶ │ ACR ログイン   │ ──▶ │ Docker ビルド     │
└───────────────┘     └───────────────┘     │ & ACR プッシュ    │
                                            └────────┬─────────┘
                                                     ▼
                                            ┌──────────────────┐
                                            │ Container Apps   │
                                            │ 更新              │
                                            └──────────────────┘
```

| ステップ | 内容 | 所要時間 |
|----------|------|---------|
| Azure ログイン | サービスプリンシパルで認証 | ~5s |
| ACR ログイン | Azure Container Registry に認証 | ~5s |
| Docker ビルド & プッシュ | イメージをビルドして ACR にプッシュ（SHA タグ + latest） | ~2m |
| Container Apps 更新 | 新しいイメージでコンテナを更新 | ~20s |

**GitHub Secrets（CD 用）:**

| シークレット名 | 用途 |
|---------------|------|
| `AZURE_CLIENT_ID` | サービスプリンシパルのクライアントID |
| `AZURE_CLIENT_SECRET` | サービスプリンシパルのシークレット |
| `AZURE_TENANT_ID` | Azure テナントID |
| `AZURE_SUBSCRIPTION_ID` | Azure サブスクリプションID |
| `ACR_LOGIN_SERVER` | ACR ログインサーバー（例: `acrdxcecopoc.azurecr.io`） |
| `ACR_NAME` | ACR 名（例: `acrdxcecopoc`） |

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

## メール通知（開発環境）

開発環境では `letter_opener_web` を使い、実際にメールを送信せずブラウザで確認できる。

### 確認手順

1. `bin/dev` でサーバーを起動
2. アプリ上でメール送信を伴う操作を行う（タスク作成、承認申請など）
3. **http://localhost:3000/letter_opener** にアクセス
4. 送信されたメールの一覧が表示される

### Rails console から手動送信

```bash
bin/rails console
```

```ruby
# タスクアサイン通知
TaskMailer.assignment_notification(Task.last).deliver_now

# 承認依頼通知
ApprovalRequestMailer.new_request(ApprovalRequest.last).deliver_now

# サーベイ配信通知
SurveyMailer.distribution(Survey.last).deliver_now

# サーベイリマインド通知
SurveyMailer.reminder(Survey.last).deliver_now
```

### メール種別一覧

| Mailer | メソッド | To | CC |
|--------|---------|-----|-----|
| TaskMailer | `assignment_notification` | アサイン先 | 部署manager + タスク作成者 |
| ApprovalRequestMailer | `new_request` | admin/manager 全員 | - |
| ApprovalRequestMailer | `approved` | 申請者 | SaaSオーナー |
| ApprovalRequestMailer | `rejected` | 申請者 | SaaSオーナー |
| SurveyMailer | `distribution` | 対象ユーザー全員 | - |
| SurveyMailer | `reminder` | 未回答ユーザーのみ | - |

### 注意事項

- 開発環境では dev_login を使うため、メール内リンクをクリックするとログイン画面に遷移する。リンクURLが正しいことを letter_opener 上で確認すればOK
- 本番環境（Entra ID SSO）ではリンクから直接該当ページに遷移する
- 本番でメール送信を有効にするには `.env` に `SMTP_*` 変数を設定する（[環境変数ガイド](environment-setup.md) 参照）

---

## Entra ID セットアップ（SSO + ユーザー同期）

### 1. アプリ登録（Azure Portal → Entra ID → アプリの登録）

1. **新規登録** をクリック
   - 名前: `SaaS管理ツール`（任意）
   - サポートされるアカウントの種類: 「この組織ディレクトリのみ」
   - リダイレクトURI: `Web` → `https://<アプリURL>/auth/entra_id/callback`
2. 作成後、以下をメモ:
   - **アプリケーション (クライアント) ID** → `ENTRA_CLIENT_ID`
   - **ディレクトリ (テナント) ID** → `ENTRA_TENANT_ID`
3. **証明書とシークレット** → 新しいクライアントシークレット → 値をメモ → `ENTRA_CLIENT_SECRET`

### 2. API のアクセス許可（アプリ登録 → API のアクセス許可）

以下の **アプリケーションの許可** を追加し、**管理者の同意** を付与する:

| API | 許可 | 種類 | 用途 |
|-----|------|------|------|
| Microsoft Graph | `User.Read.All` | アプリケーション | テナントユーザー一覧取得 |
| Microsoft Graph | `GroupMember.Read.All` | アプリケーション | グループメンバー取得（グループ同期時） |
| Microsoft Graph | `Application.Read.All` | アプリケーション | エンタープライズアプリ・割り当て取得 |

> **委任されたアクセス許可**（SSOログイン用）として `openid`, `profile`, `email` も必要。これらはデフォルトで付与済みの場合が多い。

### 3. グループベース同期の設定（推奨）

テナント全ユーザーではなく、特定グループのメンバーのみを同期する設定:

1. **Azure Portal → Entra ID → グループ** で新しいセキュリティグループを作成
   - グループ名: 「SaaS管理ツール対象ユーザー」（任意）
   - グループの種類: セキュリティ
   - メンバーシップの種類: 割り当て済み（手動管理）または動的（部署等で自動）
2. 対象ユーザーをメンバーとして追加
3. グループの **オブジェクトID** をメモ
4. Container Apps の環境変数に設定:
   ```bash
   az containerapp update --name app-dxceco-poc --resource-group rg-dxceco-poc \
     --set-env-vars ENTRA_SYNC_GROUP_ID=<グループのオブジェクトID>
   ```

> **未設定の場合**: テナント内の全ユーザーが同期される。POCや小規模テナントではこれでも問題ないが、大規模テナント（数百〜数千人）では必ずグループ指定を推奨。

### 4. 環境変数一覧（Entra ID関連）

| 環境変数 | 説明 | 必須 |
|----------|------|------|
| `ENTRA_CLIENT_ID` | アプリ登録のクライアントID | SSO利用時は必須 |
| `ENTRA_CLIENT_SECRET` | クライアントシークレット | SSO利用時は必須 |
| `ENTRA_TENANT_ID` | テナントID | SSO利用時は必須 |
| `ENTRA_SYNC_GROUP_ID` | 同期対象グループのオブジェクトID | 任意（推奨） |

### 5. SaaSアカウント同期の前提設定

Entra ID のエンタープライズアプリとSaaS台帳を紐付けるには:

1. **Entra ID → エンタープライズアプリケーション** で対象SaaSを確認
2. 各アプリの **オブジェクトID** をメモ
3. SaaS管理ツールの **SaaS台帳** → 編集 → 「Entra IDアプリID」にオブジェクトIDを入力
4. 未入力の場合はSaaS名で自動照合される（名前が一致する必要あり）

---

## タイムゾーン

アプリケーション・DBともに **JST（日本標準時）** で統一している。

| 設定 | 値 | 説明 |
|------|-----|------|
| `config.time_zone` | `"Tokyo"` | Rails のデフォルトタイムゾーン（表示・ビジネスロジック） |
| `config.active_record.default_timezone` | `:local` | DBへのタイムスタンプ保存をJSTで行う |

- `Time.current` / `Time.zone.now` は常にJSTを返す
- DB の `created_at` / `updated_at` 等もJSTで保存される
- 設定ファイル: `config/application.rb`

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
