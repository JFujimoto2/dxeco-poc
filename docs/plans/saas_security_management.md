# SaaSセキュリティ管理機能 + 部署別ビュー

## 概要

SaaS台帳にセキュリティ属性（個人情報取扱い、認証方式、データ保存先）を追加し、ダッシュボードにセキュリティリスクの可視化カードを追加する。加えて、SaaS台帳・アカウント管理画面に部署フィルターを追加し、「この部署はどのSaaSを使っているか」が一目で分かるようにする。

**GitHub Issue:** [#17](https://github.com/JFujimoto2/dxeco-poc/issues/17)

## 背景

情シス向けデモ前に「個人情報を扱うSaaSでSSO未対応」「海外にデータ保存」等のセキュリティリスクを可視化する機能を追加する。

## 変更概要

### A. セキュリティ属性（SaaS台帳に3カラム追加）

| カラム | 型 | 説明 |
|--------|-----|------|
| `handles_personal_data` | boolean (default: false) | 個人情報取扱い |
| `auth_method` | string enum (sso/password/mfa/other) | 認証方式 |
| `data_location` | string enum (domestic/overseas/unknown) | データ保存先 |

### B. 部署別ビュー

- **SaaS台帳 (`/saases`)**: 部署・認証方式・データ保存先フィルター追加
- **アカウント管理 (`/saas_accounts`)**: 部署フィルター追加
- **ダッシュボード**: 部門別リスクSaaS利用状況テーブル

### C. ダッシュボード - セキュリティリスクカード

- 個人情報取扱い・SSO未適用の件数
- 個人情報・海外データ保存の件数
- 部門別リスクSaaS利用数

## 実装ステップ（TDD）

### Step 1: マイグレーション

`db/migrate/XXXXXX_add_security_attributes_to_saases.rb`

```ruby
add_column :saases, :handles_personal_data, :boolean, default: false, null: false
add_column :saases, :auth_method, :string
add_column :saases, :data_location, :string
add_index :saases, :auth_method
add_index :saases, :data_location
```

### Step 2: モデル（テスト → 実装）

**テスト:** `spec/models/saas_spec.rb`
- auth_method / data_location enum テスト
- `filter_by_auth_method` / `filter_by_data_location` スコープ
- `personal_data_without_sso` / `personal_data_overseas` リスクスコープ

**実装:** `app/models/saas.rb`
- enum 2つ追加
- フィルタースコープ 2つ + リスクスコープ 2つ

**ファクトリ更新:** `spec/factories/saases.rb`
- セキュリティ系トレイト追加

### Step 3: SaaS台帳の部署フィルター（テスト → 実装）

**テスト:** `spec/requests/saases_spec.rb`
- 部署フィルター（`params[:department]`）で絞り込み
- セキュリティ属性フィルター（auth_method, data_location）

**実装:**
- `app/models/saas.rb`: `scope :filter_by_department`
- `app/controllers/saases_controller.rb`: index にフィルター追加、strong params にセキュリティ属性追加
- `app/views/saases/index.html.erb`: フィルタードロップダウン追加、リスクアイコン列追加

### Step 4: アカウント管理の部署フィルター（テスト → 実装）

**テスト:** `spec/requests/saas_accounts_spec.rb`
- 部署フィルター（`params[:department]`）で絞り込み

**実装:**
- `app/models/saas_account.rb`: `scope :filter_by_department`
- `app/controllers/saas_accounts_controller.rb`: index / export にフィルター追加
- `app/views/saas_accounts/index.html.erb`: 部署フィルタードロップダウン追加

### Step 5: SaaS フォーム・詳細ビュー

**テスト:** `spec/requests/saases_spec.rb`
- セキュリティ属性付きでSaaS作成
- 詳細画面にセキュリティ情報表示

**実装:**
- `app/views/saases/_form.html.erb`: 「セキュリティ情報」カード追加
- `app/views/saases/show.html.erb`: セキュリティ情報カード追加

### Step 6: ダッシュボード - セキュリティリスク（テスト → 実装）

**テスト:** `spec/requests/dashboard_spec.rb`
- SSO未適用の個人情報SaaS件数表示
- 海外データ保存の個人情報SaaS件数表示
- 部門別リスクSaaS利用数表示

**実装:**
- `app/controllers/dashboard_controller.rb`: セキュリティリスクデータ追加
- `app/views/dashboard/index.html.erb`: セキュリティリスクカード追加

### Step 7: CSV インポート/エクスポート更新

**テスト:** `spec/services/saas_import_service_spec.rb`
- セキュリティ属性付きCSVインポート

**実装:**
- `app/services/saas_import_service.rb`: header_mapping にセキュリティ属性追加
- `app/controllers/saases_controller.rb`: export / download_template にセキュリティ属性追加

### Step 8: シードデータ更新

- `db/seeds.rb`: 各SaaSにリアルなセキュリティ属性を設定

### Step 9: E2Eテスト

`e2e/security-risk.spec.ts`
- SaaS作成フォームにセキュリティ情報セクション表示
- セキュリティ属性付きSaaS作成 → 詳細で確認
- ダッシュボードにセキュリティリスクセクション表示
- SaaS一覧の認証方式・部署フィルター

### Step 10: 仕上げ

- Rubocop / Brakeman / RSpec / Playwright 全パス確認
- ドキュメント更新

## 修正ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `db/migrate/XXX_add_security_attributes_to_saases.rb` | **新規** マイグレーション |
| `app/models/saas.rb` | enum 2つ、スコープ 4つ追加 |
| `app/models/saas_account.rb` | `filter_by_department` スコープ追加 |
| `spec/factories/saases.rb` | セキュリティ系トレイト追加 |
| `spec/models/saas_spec.rb` | enum・スコープテスト追加 |
| `spec/requests/saases_spec.rb` | セキュリティ属性CRUD・フィルターテスト追加 |
| `spec/requests/saas_accounts_spec.rb` | 部署フィルターテスト追加 |
| `spec/requests/dashboard_spec.rb` | セキュリティリスクテスト追加 |
| `spec/services/saas_import_service_spec.rb` | セキュリティ属性インポートテスト追加 |
| `app/controllers/saases_controller.rb` | フィルター・strong params・エクスポート更新 |
| `app/controllers/saas_accounts_controller.rb` | 部署フィルター追加 |
| `app/controllers/dashboard_controller.rb` | セキュリティリスクデータ追加 |
| `app/views/saases/_form.html.erb` | セキュリティ情報カード追加 |
| `app/views/saases/show.html.erb` | セキュリティ情報表示追加 |
| `app/views/saases/index.html.erb` | フィルター・リスク列追加 |
| `app/views/saas_accounts/index.html.erb` | 部署フィルター追加 |
| `app/views/dashboard/index.html.erb` | セキュリティリスクカード追加 |
| `app/services/saas_import_service.rb` | セキュリティ属性マッピング追加 |
| `db/seeds.rb` | セキュリティ属性データ追加 |
| `e2e/security-risk.spec.ts` | **新規** E2Eテスト |

## 検証手順

1. `bundle exec rspec` — 全テストパス
2. `bin/rubocop` — 0 offenses
3. `bin/brakeman --no-pager` — 0 warnings
4. `npx playwright test` — 全E2Eパス
5. `rails db:seed` 後にダッシュボードでセキュリティリスクカード確認
6. SaaS一覧で部署・認証方式フィルター動作確認
7. アカウント管理で部署フィルター動作確認

## 成果物チェックリスト

- [x] マイグレーション作成・実行
- [x] Saas モデルに enum・スコープ追加
- [x] SaasAccount モデルに部署フィルタースコープ追加
- [x] ファクトリにセキュリティトレイト追加
- [x] モデルスペック作成（enum・スコープ）
- [x] SaaS台帳に部署・セキュリティフィルター追加
- [x] アカウント管理に部署フィルター追加
- [x] SaaS作成/編集フォームにセキュリティ情報追加
- [x] SaaS詳細画面にセキュリティ情報表示
- [x] ダッシュボードにセキュリティリスクカード追加
- [x] CSV インポート/エクスポートにセキュリティ属性追加
- [x] シードデータにセキュリティ属性追加
- [x] E2Eテスト作成（6テスト）
- [x] Rubocop / Brakeman / RSpec / Playwright 全パス確認（RSpec 335件 / E2E 79件）
