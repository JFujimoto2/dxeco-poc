# バッチ管理

## 概要
Entra IDとのユーザー同期や退職者アカウントの検出など、自動化されたバッチ処理の実行と履歴確認を行う管理者向け画面。

## URL
| 画面 | URL |
|------|-----|
| バッチ一覧 | `GET /admin/batches` |
| Entra IDユーザー同期 | `POST /admin/batches/sync_entra_users` |
| 退職者アカウント検出 | `POST /admin/batches/detect_retired_accounts` |
| 契約更新チェック | `POST /admin/batches/check_contract_renewals` |
| SaaSアカウント同期 | `POST /admin/batches/sync_entra_accounts` |

## バッチ種別

### Entra IDユーザー同期
- Microsoft Graph APIから全ユーザー情報を取得
- メンバー情報（名前、メール、部署、役職、アカウント状態）を更新
- `lastPasswordChangeDateTime` を取得し `last_password_change_at` に保存
- 完了後、退職者アカウント検出を自動実行

### 退職者アカウント検出
- Entra IDで無効化されたユーザーを特定
- そのユーザーがまだ保持しているSaaSアカウントを検出
- 削除漏れアカウントの発見に活用

### Entra ID SaaSアカウント同期
- Graph API `/servicePrincipals` からエンタープライズアプリ一覧を取得
- `/appRoleAssignedTo` から各アプリのユーザー割り当てを取得
- SaaS台帳の `entra_app_id` またはSaaS名で照合し、アカウントを自動同期
- 新規割り当て → アカウント作成、割り当て解除 → ステータスを `suspended` に更新
- 同期結果をTeams通知で送信

### 契約更新チェック
- 契約期限が30日以内・7日以内・期限切れのSaaSを検出
- Teams通知で更新期限アラートを送信

## 実行履歴テーブル
| 項目 | 説明 |
|------|------|
| 開始日時 | バッチ実行の開始タイムスタンプ（JST） |
| バッチ名 | sync_entra_users / detect_retired_accounts |
| ステータス | running / success / failure |
| 処理件数 | 処理したレコード数 |
| 作成件数 | 新規作成したレコード数 |
| 更新件数 | 更新したレコード数 |
| エラー件数 | エラーが発生した件数 |
| 実行時間 | バッチの所要時間 |

## アクセス権限
| ロール | 権限 |
|--------|------|
| admin | 実行 + 履歴閲覧 |
| manager | アクセス不可 |
| viewer | アクセス不可 |
