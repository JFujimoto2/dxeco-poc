# CSVインポート

## 概要
SaaS台帳とアカウント管理でCSVファイルからの一括データ登録をサポートする。手動入力の手間を削減し、既存のスプレッドシートからのデータ移行を容易にする。

## 対応画面

### SaaS台帳 CSVインポート
- **インポート**: `POST /saases/import`
- **テンプレートDL**: `GET /saases/download_template`
- **画面**: SaaS一覧画面のモーダルダイアログ（テンプレートダウンロードリンク付き）

#### CSVフォーマット
| カラム | 必須 | 説明 |
|--------|------|------|
| name | 必須 | SaaS名 |
| category | 任意 | カテゴリ |
| url | 任意 | サービスURL |
| admin_url | 任意 | 管理画面URL |
| description | 任意 | 説明 |
| status | 任意 | active / trial / cancelled（デフォルト: active） |

#### 処理ルール
- 重複するSaaS名はスキップ
- 名前が空の行はエラー
- エラー行をスキップして残りを処理
- 処理結果（成功/エラー件数）をフラッシュメッセージで表示

### アカウント CSVインポート
- **インポート**: `POST /saas_accounts/import`
- **テンプレートDL**: `GET /saas_accounts/download_template`
- **画面**: アカウント一覧画面のモーダルダイアログ（テンプレートダウンロードリンク付き）

#### CSVフォーマット
| カラム | 必須 | 説明 |
|--------|------|------|
| saas_name | 必須 | 対象SaaS名（既存のSaaS名で照合） |
| user_email | 必須 | ユーザーのメールアドレス（既存ユーザーで照合） |
| account_email | 任意 | SaaSアカウントのメール |
| role | 任意 | member / admin / owner |
| status | 任意 | active / suspended（デフォルト: active） |

#### 処理ルール
- SaaS名からsaas_idを自動解決
- メールアドレスからuser_idを自動解決
- 存在しないSaaS名・メールアドレスはエラー
- 処理結果をフラッシュメッセージで表示

## テンプレートCSVダウンロード

インポートモーダル内の「テンプレートをダウンロード」リンクからCSVテンプレートを取得できる。

- BOM付きUTF-8エンコーディング（Excel互換）
- ヘッダー行 + サンプルデータ1行を含む

## アクセス権限
admin / manager のみインポート実行可能（`require_admin_or_manager`）。
テンプレートダウンロードはログインユーザー全員が利用可能。
