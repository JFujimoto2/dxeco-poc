# フェーズ2: コア台帳機能 計画書

## 目的
SaaS台帳・契約情報・アカウント管理・メンバー管理のCRUDを実装し、260件のSaaSとアカウント情報を登録・検索・一覧表示できる状態にする。

---

## Step 1: モデル & マイグレーション

### 1.1 saases（SaaS台帳）

```ruby
create_table :saases do |t|
  t.string :name, null: false
  t.string :category             # 一般 / 不動産管理 等
  t.string :url                  # サービスURL
  t.string :admin_url            # 管理画面URL
  t.text :description            # 概要
  t.references :owner, foreign_key: { to_table: :users } # 契約担当者
  t.string :status, default: "active", null: false        # active / trial / cancelled
  t.jsonb :custom_fields, default: {}                     # カスタムフィールド
  t.timestamps
end

add_index :saases, :name
add_index :saases, :category
add_index :saases, :status
```

### 1.2 saas_contracts（契約情報）

```ruby
create_table :saas_contracts do |t|
  t.references :saas, null: false, foreign_key: true
  t.string :plan_name            # プラン名
  t.integer :price_cents         # 月額（円）
  t.string :billing_cycle        # monthly / yearly
  t.date :started_on             # 契約開始日
  t.date :expires_on             # 契約満了日
  t.string :vendor               # 提供元
  t.text :notes                  # 備考
  t.timestamps
end
```

### 1.3 saas_accounts（アカウント情報）

```ruby
create_table :saas_accounts do |t|
  t.references :saas, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.string :account_email        # SaaS側のメールアドレス
  t.string :role                 # admin / member 等
  t.string :status, default: "active", null: false  # active / suspended / deleted
  t.datetime :last_login_at      # 最終ログイン日
  t.text :notes                  # 備考
  t.timestamps
end

add_index :saas_accounts, [:saas_id, :user_id], unique: true
add_index :saas_accounts, :status
```

### 1.4 モデルのアソシエーション

```ruby
# user.rb
has_many :saas_accounts, dependent: :destroy
has_many :saases, through: :saas_accounts
has_many :owned_saases, class_name: "Saas", foreign_key: :owner_id

# saas.rb
belongs_to :owner, class_name: "User", optional: true
has_one :saas_contract, dependent: :destroy
has_many :saas_accounts, dependent: :destroy
has_many :users, through: :saas_accounts

enum :status, { active: "active", trial: "trial", cancelled: "cancelled" }
validates :name, presence: true

# saas_contract.rb
belongs_to :saas
validates :saas_id, uniqueness: true

# saas_account.rb
belongs_to :saas
belongs_to :user

enum :status, { active: "active", suspended: "suspended", deleted: "deleted" }
validates :saas_id, uniqueness: { scope: :user_id }
```

---

## Step 2: SaaS台帳 CRUD (`/saases`)

### ルーティング
```ruby
resources :saases do
  resource :saas_contract, only: [:edit, :update]
end
```

### 画面構成

| パス | アクション | 内容 |
|------|-----------|------|
| GET /saases | index | 一覧（検索・カテゴリ絞り込み・ステータスフィルタ・ページネーション） |
| GET /saases/new | new | 新規登録フォーム（契約情報も同時入力） |
| POST /saases | create | 登録 |
| GET /saases/:id | show | 詳細（契約情報 + 紐づくアカウント一覧） |
| GET /saases/:id/edit | edit | 編集フォーム |
| PATCH /saases/:id | update | 更新 |
| DELETE /saases/:id | destroy | 削除 |

### 一覧画面の機能
- キーワード検索（名前）
- カテゴリフィルタ（セレクトボックス）
- ステータスフィルタ
- Kaminari ページネーション（25件/ページ）

---

## Step 3: アカウント管理 (`/saas_accounts`)

### ルーティング
```ruby
resources :saas_accounts, except: [:show]
```

### 画面構成

| パス | アクション | 内容 |
|------|-----------|------|
| GET /saas_accounts | index | 一覧（SaaS別・ユーザー別フィルタ） |
| GET /saas_accounts/new | new | 新規登録（SaaS・ユーザー選択） |
| POST /saas_accounts | create | 登録 |
| GET /saas_accounts/:id/edit | edit | 編集 |
| PATCH /saas_accounts/:id | update | 更新 |
| DELETE /saas_accounts/:id | destroy | 削除 |

---

## Step 4: メンバー管理 (`/users`)

既存の users テーブルを一覧・詳細表示する（編集はadminのみ）。

### ルーティング
```ruby
resources :users, only: [:index, :show, :edit, :update]
```

### 画面構成

| パス | アクション | 内容 |
|------|-----------|------|
| GET /users | index | メンバー一覧（部門フィルタ・検索） |
| GET /users/:id | show | 詳細（保有アカウント一覧） |
| GET /users/:id/edit | edit | 編集（admin: ロール変更等） |
| PATCH /users/:id | update | 更新 |

---

## Step 5: ダッシュボード更新

静的だったダッシュボードに実データのサマリーを表示:
- SaaS登録数
- メンバー数
- アカウント数
- 要対応（cancelled SaaS等）

---

## Step 6: Seed データ

### SaaS（12件）
**一般:** Slack, Google Workspace, Microsoft 365, Salesforce, Zoom, Box, Notion
**不動産管理:** いえらぶCLOUD, 賃貸革命, ESいい物件One, @プロパティ, ATBB

### メンバー（5名）
開発用のサンプルユーザー

### アカウント（20件程度）
メンバー × SaaS の紐付けサンプル

---

## Step 7: RSpec テスト

### モデルスペック
- `spec/models/saas_spec.rb` - バリデーション、enum、アソシエーション
- `spec/models/saas_contract_spec.rb` - バリデーション、uniqueness
- `spec/models/saas_account_spec.rb` - バリデーション、enum、uniqueness scope

### リクエストスペック
- `spec/requests/saases_spec.rb` - CRUD全アクション + 検索・フィルタ
- `spec/requests/saas_accounts_spec.rb` - CRUD全アクション
- `spec/requests/users_spec.rb` - index, show, edit, update
- `spec/requests/dashboard_spec.rb` - サマリー表示の更新

---

## 成果物チェックリスト

- [x] saases マイグレーション & モデル
- [x] saas_contracts マイグレーション & モデル
- [x] saas_accounts マイグレーション & モデル
- [x] User モデルにアソシエーション追加
- [x] SaasesController（CRUD + 検索・フィルタ）
- [x] SaasAccountsController（CRUD）
- [x] UsersController（index, show, edit, update）
- [x] 各ビュー（一覧・フォーム・詳細）
- [x] ダッシュボード サマリー表示
- [x] Seed データ（SaaS 12件 + ユーザー5名 + アカウント19件）
- [x] ルーティング
- [x] サイドバーのリンク有効化
- [x] FactoryBot 定義（saas, saas_contract, saas_account）
- [x] モデルスペック 3ファイル
- [x] リクエストスペック 3ファイル（saases, saas_accounts, users）
- [x] `bundle exec rspec` 全46テストパス

### 実装時の補足
- `Saas` モデルの活用ルールを `config/initializers/inflections.rb` に追加（`inflect.irregular "saas", "saases"`）
- Bootstrap CDN利用（sassc-rails はPropshaftと競合するため不採用）
- 契約情報は `accepts_nested_attributes_for` でSaaSフォームに埋め込み
