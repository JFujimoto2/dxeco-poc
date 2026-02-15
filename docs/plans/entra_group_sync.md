# Entra ID グループベース同期

## 概要

現在の `EntraUserSyncJob` はテナント内の全ユーザーを同期しているが、
実運用ではSaaS管理対象のユーザーのみ（特定のEntraグループのメンバー）を同期したい。

環境変数 `ENTRA_SYNC_GROUP_ID` でグループIDを指定し、設定時はそのグループメンバーのみ同期、
未設定時は従来通り全ユーザー同期（後方互換）とする。

## 変更対象

### 1. EntraClient — `fetch_group_members` メソッド追加

- `GET /groups/{groupId}/members?$select=...&$top=999` でページネーション付き取得
- `@odata.type` が `#microsoft.graph.user` のもののみフィルタ（グループにはデバイス等も含まれうる）
- 取得する属性は `fetch_all_users` と同じ（`id, displayName, mail, userPrincipalName, jobTitle, department, employeeId, accountEnabled, lastPasswordChangeDateTime`）

### 2. EntraUserSyncJob — グループ同期対応

- `ENTRA_SYNC_GROUP_ID` が設定されている場合 → `EntraClient.fetch_group_members` を使用
- 未設定の場合 → 従来通り `EntraClient.fetch_all_users` を使用
- ログにどちらのモードで実行したか記録（BatchExecutionLog の error_messages を活用）

### 3. バッチ管理UI — 説明文更新

- グループ指定時の説明文を「指定グループのメンバーのみ同期」に変更

### 4. テスト

- `spec/services/entra_client_spec.rb` — `fetch_group_members` のテスト追加
  - 正常取得（ページネーション付き）
  - ユーザー以外のメンバー（デバイス等）をフィルタ
- `spec/jobs/entra_user_sync_job_spec.rb` — グループモードのテスト追加
  - `ENTRA_SYNC_GROUP_ID` 設定時にグループメンバーのみ同期
  - 未設定時に従来通り全ユーザー同期（既存テストの維持）

### 5. 設定

- `.env.example` に `ENTRA_SYNC_GROUP_ID=` を追加
- `CLAUDE.md` にグループ同期の説明を追記

## 環境変数

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `ENTRA_SYNC_GROUP_ID` | 同期対象のEntra IDグループのオブジェクトID | 任意（未設定時は全ユーザー同期） |

## Graph API

```
GET /groups/{groupId}/members
  ?$select=id,displayName,mail,userPrincipalName,jobTitle,department,employeeId,accountEnabled,lastPasswordChangeDateTime
  &$top=999
```

レスポンス例:
```json
{
  "value": [
    {
      "@odata.type": "#microsoft.graph.user",
      "id": "xxx",
      "displayName": "田中太郎",
      "mail": "tanaka@example.com"
    },
    {
      "@odata.type": "#microsoft.graph.device",
      "id": "yyy"
    }
  ],
  "@odata.nextLink": "..."
}
```
→ `@odata.type == "#microsoft.graph.user"` でフィルタ

## Graph API 権限

既存の `GroupMember.Read.All` または `Group.Read.All` が必要。
現在のアプリ登録の権限を確認し、不足していれば追加手順を記載。

## チェックリスト

- [x] EntraClient に `fetch_group_members` メソッド追加
- [x] EntraClient テスト追加（3テスト: 正常取得、デバイス除外、ページネーション）
- [x] EntraUserSyncJob をグループ対応に修正
- [x] EntraUserSyncJob テスト追加（2テスト: グループ同期、従来動作維持）
- [x] バッチ管理UIの説明文更新
- [x] `.env.example` 更新
- [x] CI全パス確認（RSpec 291件、Rubocop、Brakeman）
