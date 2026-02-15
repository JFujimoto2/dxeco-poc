# CSVインポート修正 & テンプレートダウンロード機能

## 概要

CSVインポート機能のバグ修正・アクセス制御追加・テンプレートCSVダウンロード機能を実装する。

## 現状の問題

1. **インポートボタンが反応しない（Turbo競合）**: `form_tag`で生成されたフォームをTurbo Driveが自動インターセプトし、Bootstrapモーダル内の`multipart/form-data`送信が正常に動作しない。`data: { turbo: false }`を追加して通常のフォーム送信にする必要がある
2. **アクセス制御なし**: `import`アクションに権限チェックがなく、viewerでもCSVインポートが実行できてしまう
3. **`require_manager`メソッド未定義**: ApplicationControllerに`require_admin`はあるが、admin/manager両方を許可するメソッドがない
4. **リクエストスペック未作成**: サービス層のテストはあるが、コントローラー経由のテスト（認証・権限・リダイレクト等）がない
5. **テンプレートCSVダウンロード機能がない**: インポートモーダルにフォーマット説明のテキストのみで、テンプレートファイルをダウンロードできない

## 実装計画

### 0. インポートフォームのTurbo競合を修正
- **ファイル**: `app/views/saases/_import_form.html.erb`
- **ファイル**: `app/views/saas_accounts/_import_form.html.erb`
- `form_tag`に`data: { turbo: false }`を追加してTurbo Driveをバイパス
- これにより通常のHTTPフォーム送信となり、`redirect_to`が正常に動作する

### 1. ApplicationControllerに`require_admin_or_manager`メソッドを追加
- **ファイル**: `app/controllers/application_controller.rb`
- admin または manager ロールのユーザーのみ許可するヘルパーメソッド

### 2. インポートアクションにアクセス制御を追加
- **ファイル**: `app/controllers/saases_controller.rb`
  - `before_action :require_admin_or_manager, only: [:import]`
- **ファイル**: `app/controllers/saas_accounts_controller.rb`
  - `before_action :require_admin_or_manager, only: [:import]`

### 3. CSVテンプレートダウンロードアクションを追加
- **ルーティング**: 各リソースのcollectionに`GET :download_template`を追加
  - `GET /saases/download_template`
  - `GET /saas_accounts/download_template`
- **コントローラー**: BOM付きUTF-8のCSVテンプレートを動的生成して`send_data`
  - SaaS: ヘッダー行 + サンプル1行
  - アカウント: ヘッダー行 + サンプル1行

### 4. インポートモーダルにテンプレートダウンロードリンクを追加
- **ファイル**: `app/views/saases/_import_form.html.erb`
- **ファイル**: `app/views/saas_accounts/_import_form.html.erb`
- モーダル内に「テンプレートをダウンロード」リンクを追加

### 5. テスト作成

#### リクエストスペック（新規追加）
- **ファイル**: `spec/requests/saases_spec.rb` に追加
  - `POST /saases/import`: CSVアップロードで一括登録
  - `POST /saases/import`: ファイル未選択でエラーメッセージ
  - `POST /saases/import`: viewer権限でリダイレクト
  - `GET /saases/download_template`: テンプレートCSVをダウンロード
- **ファイル**: `spec/requests/saas_accounts_spec.rb` に追加
  - `POST /saas_accounts/import`: CSVアップロードで一括登録
  - `POST /saas_accounts/import`: ファイル未選択でエラーメッセージ
  - `POST /saas_accounts/import`: viewer権限でリダイレクト
  - `GET /saas_accounts/download_template`: テンプレートCSVをダウンロード

#### Playwright E2Eテスト（新規ファイル）
- **ファイル**: `e2e/csv-import.spec.ts`
  - SaaS台帳: CSVインポートモーダルを開く → テンプレートDLリンクが表示される
  - SaaS台帳: テンプレートCSVをダウンロードできる
  - SaaS台帳: CSVファイルをアップロードしてインポートが成功する → フラッシュメッセージ確認
  - アカウント: CSVインポートモーダルを開く → テンプレートDLリンクが表示される
  - アカウント: テンプレートCSVをダウンロードできる
  - アカウント: CSVファイルをアップロードしてインポートが成功する → フラッシュメッセージ確認

### 6. ドキュメント更新
- `docs/features/11_csv_import.md` をテンプレートダウンロード機能の説明で更新

## ルーティング変更

```ruby
resources :saases do
  collection do
    post :import
    get :download_template    # 追加
  end
end
resources :saas_accounts, except: [:show] do
  collection do
    post :import
    get :download_template    # 追加
  end
end
```

## CSVテンプレート内容

### SaaS台帳テンプレート (`saas_template.csv`)
```csv
name,category,url,admin_url,description,status
サンプルSaaS,一般,https://example.com,,サービスの説明,active
```

### アカウントテンプレート (`saas_account_template.csv`)
```csv
saas_name,user_email,account_email,role,status
Slack,user@example.com,user@example.com,member,active
```

## 成果物チェックリスト

- [ ] インポートフォームの Turbo 競合修正（`data: { turbo: false }`）
- [ ] `require_admin_or_manager` メソッド追加
- [ ] SaaSインポートにアクセス制御追加
- [ ] アカウントインポートにアクセス制御追加
- [ ] SaaSテンプレートダウンロードアクション追加
- [ ] アカウントテンプレートダウンロードアクション追加
- [ ] ルーティング更新
- [ ] インポートモーダルにテンプレートDLリンク追加（SaaS）
- [ ] インポートモーダルにテンプレートDLリンク追加（アカウント）
- [ ] リクエストスペック追加（SaaS import + download_template）
- [ ] リクエストスペック追加（アカウント import + download_template）
- [ ] Playwright E2Eテスト追加（`e2e/csv-import.spec.ts`）
- [ ] `docs/features/11_csv_import.md` 更新
- [ ] Rubocop + RSpec + Playwright 全パス確認
