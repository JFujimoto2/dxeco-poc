# Entra ID SaaSアカウント同期 + パスワード期限検出

## 概要
Entra ID（Microsoft Graph API）と連携し、エンタープライズアプリのユーザー割り当てからSaaSアカウント台帳を自動同期する。また、パスワード期限切れ・期限間近のユーザーを検出してダッシュボードに表示する。

## SaaSアカウント自動同期

### 仕組み
1. Graph API `/servicePrincipals` からエンタープライズアプリ一覧を取得
2. SaaS台帳の `entra_app_id`（またはSaaS名）で照合
3. `/appRoleAssignedTo` から各アプリのユーザー割り当てを取得
4. SaaSアカウント台帳と差分同期

### 同期ルール
| ケース | アクション |
|--------|-----------|
| Entraに割り当てあり、台帳になし | アカウントを新規作成（status: active） |
| Entraに割り当てなし、台帳にあり | ステータスを `suspended` に更新 |
| 両方にあり | 変更なし |

### SaaSとの照合方法
1. `saases.entra_app_id` とエンタープライズアプリの `id` で完全一致
2. 一致しない場合、SaaS名とアプリの `displayName` で大文字小文字を無視して照合

### 設定方法
SaaS台帳の編集画面で「Entra ID アプリID」フィールドにエンタープライズアプリのオブジェクトIDを設定する。

## パスワード期限検出

### 仕組み
- Entra IDユーザー同期時に `lastPasswordChangeDateTime` を取得
- `users.last_password_change_at` に保存
- 90日ポリシーに基づいて期限判定

### スコープ
| スコープ | 条件 |
|----------|------|
| `password_expired` | `last_password_change_at` が90日以上前（有効ユーザーのみ） |
| `password_expiring_soon(14)` | `last_password_change_at` が76〜90日前（14日以内に期限切れ） |

### ダッシュボード表示
- 期限切れ・期限間近のユーザーをカード形式で表示
- ユーザー名、部署、最終パスワード変更日、残日数を表示

## バッチ実行
- **URL**: `POST /admin/batches/sync_entra_accounts`
- `EntraAccountSyncJob` を実行
- 実行結果を `BatchExecutionLog` に記録
- 同期結果をTeams通知で送信（新規・停止件数、対象SaaS名）

## アクセス権限
バッチ実行はadminのみ。ダッシュボードのパスワードアラートは全ロールに表示。
