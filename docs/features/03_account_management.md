# アカウント管理

## 概要
各SaaSに対するユーザーのアカウント割り当てを管理する。誰がどのSaaSを使っているかを一元的に把握できる。

## URL
| 画面 | URL |
|------|-----|
| 一覧 | `GET /saas_accounts` |
| 新規登録 | `GET /saas_accounts/new` |
| 編集 | `GET /saas_accounts/:id/edit` |
| CSVインポート | `POST /saas_accounts/import` |

※ 個別のshowページはなし（一覧から直接編集）

## データ項目
| 項目 | 説明 |
|------|------|
| SaaS | 対象のSaaSサービス |
| メンバー | アカウントを持つユーザー |
| アカウントメール | SaaSログイン用のメールアドレス |
| ロール | admin / member / owner |
| ステータス | active / suspended / deleted |
| 最終ログイン日時 | 最後にSaaSにログインした日時 |

## 一覧画面の機能
- **SaaSフィルタ**: 特定のSaaSのアカウントだけ表示
- **メンバーフィルタ**: 特定ユーザーのアカウントだけ表示
- **ステータスフィルタ**: active / suspended / deleted で絞り込み
- **CSVインポート**: CSVファイルからの一括登録
- **インライン操作**: 各行に編集・削除ボタン
- **ページネーション**

## ユニーク制約
- SaaS + ユーザーの組み合わせは一意（同じユーザーが同じSaaSに2つアカウントを持てない）

## アクセス権限
| ロール | 権限 |
|--------|------|
| admin | CRUD + CSVインポート |
| manager | CRUD |
| viewer | 閲覧のみ |
