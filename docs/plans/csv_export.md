# CSVエクスポート

## 概要

SaaS台帳、アカウント一覧、監査ログの各一覧画面にCSVエクスポートボタンを追加する。フィルタ条件を適用した状態でエクスポートできるようにする。

**GitHub Issue:** [#7](https://github.com/JFujimoto2/dxeco-poc/issues/7)

## 前提

- CSVインポート機能が既に実装済み（`download_template` パターンを踏襲）
- BOM付きUTF-8（`\uFEFF`）で出力（Excel互換）
- フィルタ条件はクエリパラメータで引き継ぐ

## 実装計画

### 1. SaaS台帳エクスポート

**ファイル**: `app/controllers/saases_controller.rb`

`export` アクション追加:
- 既存の `index` と同じフィルタ条件を適用（`q`, `category`, `status`）
- ページネーションなしで全件取得
- 契約情報（プラン、月額、請求サイクル、期限）も含める
- カラム: SaaS名, カテゴリ, ステータス, URL, 担当者, プラン, 月額, 請求サイクル, 契約期限

**ファイル**: `app/views/saases/index.html.erb`

- CSVインポートボタンの隣にCSVエクスポートボタンを追加

**ファイル**: `config/routes.rb`

```ruby
collection do
  get :export
end
```

### 2. アカウント一覧エクスポート

**ファイル**: `app/controllers/saas_accounts_controller.rb`

`export` アクション追加:
- フィルタ条件: `saas_id`, `user_id`, `status`
- カラム: SaaS名, メンバー名, 部署, アカウントメール, ロール, ステータス, 最終ログイン

**ファイル**: `app/views/saas_accounts/index.html.erb`

- エクスポートボタン追加

### 3. 監査ログエクスポート

**ファイル**: `app/controllers/admin/audit_logs_controller.rb`

`export` アクション追加（admin のみ）:
- フィルタ条件: `resource_type`, `user_id`, `date_from`, `date_to`
- カラム: 日時, 操作, リソース種別, リソースID, ユーザー, IPアドレス

**ファイル**: `app/views/admin/audit_logs/index.html.erb`

- エクスポートボタン追加

### 4. テスト

#### RSpec

- **`spec/requests/saases_spec.rb`**: export テスト（CSV形式確認、フィルタ適用）
- **`spec/requests/saas_accounts_spec.rb`**: export テスト
- **`spec/requests/admin/audit_logs_spec.rb`**: export テスト（admin権限）

#### Playwright E2E

- **`e2e/csv-export.spec.ts`**: 各画面のエクスポートボタンが存在し、CSVダウンロードできる

## 成果物チェックリスト

- [x] SaaS台帳エクスポート（コントローラー + ルート + ビュー）
- [x] アカウント一覧エクスポート（コントローラー + ルート + ビュー）
- [x] 監査ログエクスポート（コントローラー + ルート + ビュー）
- [x] RSpec テスト作成（6件）
- [x] Playwright E2E テスト追加（`e2e/csv-export.spec.ts` — 3テスト）
- [x] Rubocop + RSpec(253) + Playwright(73) 全パス確認
