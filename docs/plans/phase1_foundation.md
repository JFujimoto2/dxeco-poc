# フェーズ1: 基盤構築 計画書

## 目的
Rails アプリの土台を構築する。認証・権限・レイアウト・テスト環境を整え、フェーズ2以降の機能開発に着手できる状態にする。

---

## Step 1: Gem追加

### Gemfile に追加するgem

```ruby
# --- 認証 ---
gem "omniauth"
gem "omniauth-openid-connect"
gem "omniauth-rails_csrf_protection"
gem "faraday"                          # Graph API呼び出し用

# --- UI ---
gem "bootstrap", "~> 5.3"
gem "sassc-rails"
gem "bootstrap-icons-helper"
gem "kaminari"                         # ページネーション

# --- テスト ---
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end
```

### セットアップコマンド

```bash
bundle install
rails generate rspec:install
```

---

## Step 2: Bootstrap 導入

### 2.1 SCSS ファイル

`app/assets/stylesheets/application.bootstrap.scss` を新規作成:
```scss
@import "bootstrap";
```

既存の `application.css` は Bootstrap を読み込む形に変更するか、propshaft 経由で `application.bootstrap.scss` を読み込む。

### 2.2 JavaScript（importmap）

```bash
bin/importmap pin bootstrap
```

`app/javascript/application.js` に追加:
```js
import "bootstrap"
```

### 2.3 Bootstrap Icons

CDN リンクをレイアウトの `<head>` に追加:
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
```

---

## Step 3: Users テーブル（認証ユーザー）

### マイグレーション

```ruby
create_table :users do |t|
  t.string :entra_id_sub, null: false, index: { unique: true }
  t.string :email, null: false
  t.string :display_name
  t.string :department
  t.string :job_title
  t.string :employee_id
  t.boolean :account_enabled, default: true
  t.string :role, default: "viewer"  # admin / manager / viewer
  t.datetime :last_signed_in_at
  t.timestamps
end
```

### モデル（`app/models/user.rb`）

```ruby
class User < ApplicationRecord
  enum :role, { viewer: "viewer", manager: "manager", admin: "admin" }

  validates :entra_id_sub, presence: true, uniqueness: true
  validates :email, presence: true
  validates :role, presence: true
end
```

---

## Step 4: Entra ID SSO 認証

### 4.1 OmniAuth 設定

`config/initializers/omniauth.rb`:
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :entra_id,
    scope: [:openid, :profile, :email],
    issuer: "https://login.microsoftonline.com/#{ENV['ENTRA_TENANT_ID']}/v2.0",
    client_options: {
      identifier: ENV["ENTRA_CLIENT_ID"],
      secret: ENV["ENTRA_CLIENT_SECRET"],
      redirect_uri: "#{ENV['APP_URL']}/auth/entra_id/callback"
    }
end

OmniAuth.config.allowed_request_methods = [:post]
```

### 4.2 開発環境スキップ

Entra ID が未設定の開発環境でも動作するよう、**開発用ログイン**を用意する:
- `ENTRA_CLIENT_ID` が未設定の場合、開発用ログインフォーム（名前・メール入力）を表示
- 入力した情報で User を作成/検索してログイン
- 本番では必ず Entra ID 経由のみ

### 4.3 SessionsController

```ruby
class SessionsController < ApplicationController
  skip_before_action :require_login

  # POST /auth/entra_id/callback
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(entra_id_sub: auth.uid)
    user.assign_attributes(
      email: auth.info.email,
      display_name: auth.info.name,
      last_signed_in_at: Time.current
    )
    user.role ||= "viewer"
    user.save!
    session[:user_id] = user.id
    redirect_to root_path, notice: "ログインしました"
  end

  # DELETE /logout
  def destroy
    reset_session
    redirect_to login_path, notice: "ログアウトしました"
  end

  # GET /login (開発環境用)
  def new; end

  # POST /dev_login (開発環境用)
  def dev_create
    return head :forbidden unless Rails.env.development?
    user = User.find_or_initialize_by(email: params[:email])
    user.assign_attributes(
      entra_id_sub: SecureRandom.uuid,
      display_name: params[:display_name],
      role: params[:role] || "admin",
      last_signed_in_at: Time.current
    )
    user.save!
    session[:user_id] = user.id
    redirect_to root_path, notice: "開発ログインしました"
  end
end
```

### 4.4 ApplicationController（認証フィルタ）

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    unless current_user
      redirect_to login_path
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end
```

---

## Step 5: ルーティング

```ruby
Rails.application.routes.draw do
  # 認証
  get  "login",  to: "sessions#new"
  post "dev_login", to: "sessions#dev_create" if Rails.env.development?
  delete "logout", to: "sessions#destroy"
  get "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: redirect("/login")

  # ダッシュボード
  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## Step 6: レイアウト & ダッシュボード

### 6.1 サイドバー付きレイアウト

`app/views/layouts/application.html.erb` をサイドバー + メインコンテンツの2カラム構成に変更。

サイドバーのナビ項目（フェーズ2以降で順次リンク先を実装）:
- ダッシュボード
- SaaS台帳
- アカウント管理
- メンバー
- サーベイ
- タスク管理
- 申請・承認
- （admin）バッチ管理
- （admin）操作ログ

### 6.2 DashboardController

```ruby
class DashboardController < ApplicationController
  def index
    # フェーズ1では静的なウェルカム画面のみ
    # フェーズ2以降でサマリー情報を追加
  end
end
```

---

## Step 7: RSpec テスト

### 7.1 FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:entra_id_sub) { |n| "entra-#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "テストユーザー" }
    role { "viewer" }

    trait :admin do
      role { "admin" }
    end

    trait :manager do
      role { "manager" }
    end
  end
end
```

### 7.2 モデルスペック

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  it "バリデーションが通る" do
    user = build(:user)
    expect(user).to be_valid
  end

  it "entra_id_sub が必須" do
    user = build(:user, entra_id_sub: nil)
    expect(user).not_to be_valid
  end

  it "entra_id_sub が一意" do
    create(:user, entra_id_sub: "same-id")
    user = build(:user, entra_id_sub: "same-id")
    expect(user).not_to be_valid
  end

  it "email が必須" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
  end

  it "ロールが正しく動作する" do
    admin = build(:user, :admin)
    expect(admin).to be_admin
  end
end
```

### 7.3 リクエストスペック

```ruby
# spec/requests/dashboard_spec.rb
RSpec.describe "Dashboard", type: :request do
  it "未ログインはログイン画面にリダイレクト" do
    get root_path
    expect(response).to redirect_to(login_path)
  end

  it "ログイン済みはダッシュボードを表示" do
    user = create(:user)
    post dev_login_path, params: { email: user.email, display_name: user.display_name }
    get root_path
    expect(response).to have_http_status(:ok)
  end
end

# spec/requests/sessions_spec.rb
RSpec.describe "Sessions", type: :request do
  it "開発ログインできる" do
    post dev_login_path, params: { email: "test@example.com", display_name: "テスト" }
    expect(response).to redirect_to(root_path)
  end

  it "ログアウトできる" do
    user = create(:user)
    post dev_login_path, params: { email: user.email, display_name: user.display_name }
    delete logout_path
    expect(response).to redirect_to(login_path)
  end
end
```

---

## 成果物チェックリスト

- [x] Gem 追加 & `bundle install`
- [x] RSpec セットアップ (`rails g rspec:install`)
- [x] Bootstrap 導入（CDN + importmap JS + Icons）
- [x] users マイグレーション & モデル
- [x] OmniAuth 設定（`config/initializers/omniauth.rb`）
- [x] SessionsController（Entra ID コールバック + 開発用ログイン）
- [x] ApplicationController（認証フィルタ + current_user）
- [x] ルーティング
- [x] サイドバー付きレイアウト
- [x] DashboardController + ビュー
- [x] ログイン画面ビュー
- [x] FactoryBot + User スペック
- [x] リクエストスペック（Dashboard, Sessions）
- [x] `bundle exec rspec` 全14テストパス
