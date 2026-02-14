# Entra ID SaaSアカウント自動同期 + パスワード期限検出

## 概要

Entra ID のエンタープライズアプリ（SSO連携済みSaaS）のユーザー割り当て情報を Graph API で取得し、SaaSアカウント台帳を自動同期する。あわせてパスワード期限切れ・期限間近のユーザーを検出してダッシュボードに表示する。

**GitHub Issue:** [#10](https://github.com/JFujimoto2/dxeco-poc/issues/10)

## 前提

- `EntraClient` が Client Credentials フローで Graph API にアクセス済み
- `EntraUserSyncJob` がユーザー同期の実績あり（BatchExecutionLog パターン確立済み）
- `TeamsNotifier` で通知基盤が整備済み
- SaaS台帳（`saases`テーブル）、アカウント台帳（`saas_accounts`テーブル）が存在

## Graph API エンドポイント

| 用途 | エンドポイント | 備考 |
|------|---------------|------|
| エンタープライズアプリ一覧 | `GET /servicePrincipals?$filter=tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')` | SSO連携済みアプリのみ |
| アプリのユーザー割り当て | `GET /servicePrincipals/{id}/appRoleAssignedTo` | 各アプリに割り当てられたユーザー |
| ユーザーのパスワード情報 | `GET /users?$select=id,lastPasswordChangeDateTime` | パスワード最終変更日 |

## 実装計画

### 1. DBマイグレーション

#### 1.1 saases テーブルに `entra_app_id` カラム追加

```ruby
add_column :saases, :entra_app_id, :string
add_index :saases, :entra_app_id, unique: true
```

- Entra ID のサービスプリンシパルID（UUID）を格納
- 初回同期で名前マッチング → 以降はIDでマッチング
- nullable（全SaaSがEntra連携しているわけではない）

#### 1.2 users テーブルに `last_password_change_at` カラム追加

```ruby
add_column :users, :last_password_change_at, :datetime
```

- Graph API の `lastPasswordChangeDateTime` を格納
- パスワード期限切れ検出に使用

### 2. EntraClient 拡張

**ファイル**: `app/services/entra_client.rb`

#### 2.1 `fetch_service_principals(token)`
- SSO連携済みエンタープライズアプリ一覧を取得
- `$filter=tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')`
- `$select=id,displayName,appId`
- ページネーション対応（`@odata.nextLink`）

#### 2.2 `fetch_app_role_assignments(token, service_principal_id)`
- 指定アプリに割り当てられたユーザー一覧を取得
- `$select=principalId,principalDisplayName,principalType`
- `principalType == "User"` のみ対象

#### 2.3 `fetch_all_users` に `lastPasswordChangeDateTime` を追加
- 既存の `$select` に `lastPasswordChangeDateTime` を追加

### 3. EntraUserSyncJob 拡張

**ファイル**: `app/jobs/entra_user_sync_job.rb`

- `lastPasswordChangeDateTime` を `last_password_change_at` に同期

### 4. EntraAccountSyncJob（新規）

**ファイル**: `app/jobs/entra_account_sync_job.rb`

処理フロー:
1. BatchExecutionLog を作成（status: running）
2. `fetch_service_principals` でエンタープライズアプリ一覧を取得
3. 各アプリについて:
   a. `entra_app_id` でSaaSレコードをマッチング（未設定なら `displayName` で名前マッチング）
   b. マッチしたSaaSの `entra_app_id` を更新（初回マッチング時）
   c. `fetch_app_role_assignments` でユーザー割り当てを取得
   d. 各ユーザーについて:
      - `principalId` → User の `entra_id_sub` でユーザーを特定
      - SaasAccount が存在しなければ作成（status: active）
      - 既存の active アカウントが割り当てから消えていたら `suspended` に更新
4. 同期統計を BatchExecutionLog に記録
5. Teams 通知を送信

### 5. User モデルにパスワード期限スコープ追加

**ファイル**: `app/models/user.rb`

```ruby
PASSWORD_EXPIRY_DAYS = 90

scope :password_expired, -> {
  where("last_password_change_at < ?", PASSWORD_EXPIRY_DAYS.days.ago)
    .where(account_enabled: true)
}

scope :password_expiring_soon, ->(warn_days = 14) {
  cutoff = PASSWORD_EXPIRY_DAYS.days.ago
  warn_cutoff = (PASSWORD_EXPIRY_DAYS - warn_days).days.ago
  where(last_password_change_at: cutoff..warn_cutoff)
    .where(account_enabled: true)
}
```

### 6. ダッシュボードにパスワード期限アラート追加

**ファイル**: `app/controllers/dashboard_controller.rb`

```ruby
@password_expired_users = User.password_expired.order(:last_password_change_at)
@password_expiring_users = User.password_expiring_soon.order(:last_password_change_at)
```

**ファイル**: `app/views/dashboard/index.html.erb`

- 契約更新アラートセクションの下にパスワード期限アラートセクションを追加
- 期限切れユーザー（赤）+ 期限間近ユーザー（黄）をテーブル表示
- 表示項目: ユーザー名、部署、最終パスワード変更日、残り日数

### 7. SaaS管理画面に `entra_app_id` 表示

**ファイル**: `app/views/saases/show.html.erb`

- 詳細画面に Entra ID 連携情報を表示（entra_app_id がある場合のみ）

**ファイル**: `app/views/saases/_form.html.erb`

- フォームに `entra_app_id` フィールドを追加（手動マッピング用）

**ファイル**: `app/controllers/saases_controller.rb`

- Strong Parameters に `entra_app_id` を追加

### 8. バッチ管理画面に手動実行ボタン追加

**ファイル**: `app/controllers/admin/batches_controller.rb`

```ruby
def sync_entra_accounts
  EntraAccountSyncJob.perform_later
  redirect_to admin_batches_path, notice: "SaaSアカウント同期を開始しました"
end
```

**ファイル**: `app/views/admin/batches/index.html.erb`

- 「SaaSアカウント同期」ボタンを追加

**ファイル**: `config/routes.rb`

```ruby
post :sync_entra_accounts
```

### 9. Teams 通知

同期完了時に以下を通知:
- 検出したエンタープライズアプリ数
- マッチしたSaaS数
- 新規作成アカウント数 / 停止アカウント数
- パスワード期限切れユーザー数

### 10. テスト

#### RSpec

- **`spec/models/user_spec.rb`**: `password_expired`, `password_expiring_soon` スコープテスト
- **`spec/services/entra_client_spec.rb`**: 新メソッドのテスト（WebMock）
- **`spec/jobs/entra_account_sync_job_spec.rb`**（新規）:
  - エンタープライズアプリからSaaSアカウントが同期される
  - 名前マッチングで `entra_app_id` が設定される
  - 割り当て解除されたアカウントが suspended になる
  - マッチするSaaSがない場合もエラーにならない
  - BatchExecutionLog が作成される
  - Teams 通知が送信される
- **`spec/requests/dashboard_spec.rb`**: パスワード期限アラート表示テスト
- **`spec/requests/admin/batches_spec.rb`**: sync_entra_accounts テスト

#### Playwright E2E

- **`e2e/entra-account-sync.spec.ts`**（新規）:
  - ダッシュボードにパスワード期限アラートセクションが表示される
  - バッチ管理画面にSaaSアカウント同期ボタンが表示される

## 成果物チェックリスト

- [x] マイグレーション: `saases.entra_app_id` カラム追加
- [x] マイグレーション: `users.last_password_change_at` カラム追加
- [x] EntraClient に `fetch_service_principals` メソッド追加
- [x] EntraClient に `fetch_app_role_assignments` メソッド追加
- [x] EntraClient の `fetch_all_users` に `lastPasswordChangeDateTime` 追加
- [x] EntraUserSyncJob で `last_password_change_at` を同期
- [x] EntraAccountSyncJob 新規作成
- [x] User モデルにパスワード期限スコープ追加
- [x] ダッシュボードにパスワード期限アラート追加
- [x] SaaS フォームに `entra_app_id` フィールド追加
- [x] バッチ管理画面に同期ボタン追加
- [x] ルーティング更新
- [x] Teams 通知
- [x] RSpec テスト作成（238テスト全パス）
- [x] Playwright E2E テスト追加（68テスト全パス）
- [x] Rubocop + RSpec + Playwright 全パス確認
