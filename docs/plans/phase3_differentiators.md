# フェーズ3: 差別化機能 計画書

## 目的
POCの核心となる4つの差別化機能を実装する。DXECOと同等のサーベイ・タスク管理に加え、DXECOにない申請承認フロー・退職者自動検出を実装し、自社開発の優位性を実証する。

---

## Step 1: バッチ実行基盤 & 退職者アカウント検出

バッチ実行ログ・EntraClient・TeamsNotifier の共通基盤を先に構築する。

### 1.1 batch_execution_logs マイグレーション

```ruby
create_table :batch_execution_logs do |t|
  t.string :job_name, null: false
  t.string :status, null: false, default: "running"  # running / success / failure
  t.datetime :started_at
  t.datetime :finished_at
  t.integer :processed_count, default: 0
  t.integer :created_count, default: 0
  t.integer :updated_count, default: 0
  t.integer :error_count, default: 0
  t.text :error_messages
  t.timestamps
end
```

### 1.2 BatchExecutionLog モデル

```ruby
class BatchExecutionLog < ApplicationRecord
  enum :status, { running: "running", success: "success", failure: "failure" }
  validates :job_name, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
```

### 1.3 EntraClient サービス（`app/services/entra_client.rb`）

Graph API 呼び出し用クライアント。POCでは手動実行ボタンからの利用。

```ruby
class EntraClient
  BASE_URL = "https://graph.microsoft.com/v1.0"

  def self.fetch_app_token
    tenant_id = ENV["ENTRA_TENANT_ID"]
    response = Faraday.post(
      "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token",
      client_id: ENV["ENTRA_CLIENT_ID"],
      client_secret: ENV["ENTRA_CLIENT_SECRET"],
      scope: "https://graph.microsoft.com/.default",
      grant_type: "client_credentials"
    )
    JSON.parse(response.body)["access_token"]
  end

  def self.fetch_all_users(token)
    url = "#{BASE_URL}/users?$select=id,displayName,mail,jobTitle,department,employeeId,accountEnabled&$top=999"
    users = []
    loop do
      response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{token}"
      end
      data = JSON.parse(response.body)
      users.concat(data["value"] || [])
      url = data["@odata.nextLink"]
      break unless url
    end
    users
  end
end
```

### 1.4 TeamsNotifier サービス（`app/services/teams_notifier.rb`）

Power Automate Workflows Webhook 経由の Teams 通知。

```ruby
class TeamsNotifier
  WEBHOOK_URL = ENV["TEAMS_WEBHOOK_URL"]

  def self.notify(title:, body:, level: :info)
    return unless WEBHOOK_URL.present?

    payload = {
      type: "message",
      attachments: [{
        contentType: "application/vnd.microsoft.card.adaptive",
        content: {
          "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
          type: "AdaptiveCard",
          version: "1.4",
          body: [
            { type: "TextBlock", text: title, weight: "Bolder", size: "Medium" },
            { type: "TextBlock", text: body, wrap: true }
          ]
        }
      }]
    }
    Faraday.post(WEBHOOK_URL, payload.to_json, "Content-Type" => "application/json")
  end
end
```

### 1.5 EntraUserSyncJob（`app/jobs/entra_user_sync_job.rb`）

```ruby
class EntraUserSyncJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)
    stats = { processed_count: 0, created_count: 0, updated_count: 0, error_count: 0 }

    token = EntraClient.fetch_app_token
    entra_users = EntraClient.fetch_all_users(token)

    entra_users.each do |eu|
      user = User.find_or_initialize_by(entra_id_sub: eu["id"])
      user.assign_attributes(
        email: eu["mail"] || eu["userPrincipalName"],
        display_name: eu["displayName"],
        department: eu["department"],
        job_title: eu["jobTitle"],
        employee_id: eu["employeeId"],
        account_enabled: eu["accountEnabled"]
      )
      user.role ||= "viewer"
      stats[:created_count] += 1 if user.new_record?
      stats[:updated_count] += 1 if user.persisted? && user.changed?
      user.save!
      stats[:processed_count] += 1
    rescue => e
      stats[:error_count] += 1
    end

    log.update!(status: "success", finished_at: Time.current, **stats)
    RetiredAccountDetectionJob.perform_later
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end
end
```

### 1.6 RetiredAccountDetectionJob（`app/jobs/retired_account_detection_job.rb`）

```ruby
class RetiredAccountDetectionJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)

    retired_users = User.where(account_enabled: false)
    results = []

    retired_users.find_each do |user|
      remaining = user.saas_accounts.where(status: "active").includes(:saas)
      if remaining.any?
        results << {
          user_name: user.display_name,
          user_email: user.email,
          accounts: remaining.map { |a| { saas_name: a.saas.name, email: a.account_email } }
        }
      end
    end

    log.update!(
      status: "success",
      finished_at: Time.current,
      processed_count: retired_users.count,
      created_count: results.size,
      error_messages: results.any? ? results.to_json : nil
    )

    if results.any?
      TeamsNotifier.notify(
        title: "退職者アカウント検出: #{results.size}名",
        body: results.map { |r|
          "#{r[:user_name]} (#{r[:user_email]})\n" +
          r[:accounts].map { |a| "  - #{a[:saas_name]}: #{a[:email]}" }.join("\n")
        }.join("\n\n"),
        level: :warning
      )
    end
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end
end
```

### 1.7 Admin::BatchesController

```ruby
class Admin::BatchesController < ApplicationController
  before_action :require_admin

  def index
    @logs = BatchExecutionLog.recent.page(params[:page]).per(20)
  end

  def sync_entra_users
    EntraUserSyncJob.perform_later
    redirect_to admin_batches_path, notice: "Entra IDユーザー同期を開始しました"
  end

  def detect_retired_accounts
    RetiredAccountDetectionJob.perform_later
    redirect_to admin_batches_path, notice: "退職者アカウント検出を開始しました"
  end
end
```

### 1.8 ルーティング

```ruby
namespace :admin do
  resources :batches, only: [:index] do
    collection do
      post :sync_entra_users
      post :detect_retired_accounts
    end
  end
end
```

### 1.9 画面

- `admin/batches/index.html.erb` - 実行ボタン + 実行履歴テーブル

---

## Step 2: アカウントサーベイ

### 2.1 surveys マイグレーション

```ruby
create_table :surveys do |t|
  t.string :title, null: false
  t.string :survey_type, null: false, default: "account_review"  # account_review / password_update
  t.references :created_by, null: false, foreign_key: { to_table: :users }
  t.string :status, null: false, default: "draft"  # draft / active / closed
  t.datetime :sent_at
  t.datetime :deadline
  t.timestamps
end

add_index :surveys, :status
```

### 2.2 survey_responses マイグレーション

```ruby
create_table :survey_responses do |t|
  t.references :survey, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.references :saas_account, foreign_key: true
  t.string :response           # using / not_using / updated
  t.datetime :responded_at
  t.text :notes
  t.timestamps
end

add_index :survey_responses, [:survey_id, :user_id, :saas_account_id], unique: true, name: "idx_survey_responses_unique"
```

### 2.3 モデル

```ruby
# survey.rb
class Survey < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :survey_responses, dependent: :destroy

  enum :survey_type, { account_review: "account_review", password_update: "password_update" }
  enum :status, { draft: "draft", active: "active", closed: "closed" }

  validates :title, presence: true

  def response_rate
    return 0 if target_user_count.zero?
    (responded_user_count.to_f / target_user_count * 100).round(1)
  end

  def target_user_count
    survey_responses.select(:user_id).distinct.count
  end

  def responded_user_count
    survey_responses.where.not(responded_at: nil).select(:user_id).distinct.count
  end
end

# survey_response.rb
class SurveyResponse < ApplicationRecord
  belongs_to :survey
  belongs_to :user
  belongs_to :saas_account, optional: true

  validates :survey_id, uniqueness: { scope: [:user_id, :saas_account_id] }

  scope :pending, -> { where(responded_at: nil) }
  scope :responded, -> { where.not(responded_at: nil) }
  scope :not_using, -> { where(response: "not_using") }
end
```

### 2.4 SurveysController

```ruby
class SurveysController < ApplicationController
  before_action :require_admin, only: [:new, :create, :close, :remind]

  # GET /surveys - 一覧（管理者: 全サーベイ、一般: 自分の回答対象）
  def index
    @surveys = if current_user.admin?
      Survey.order(created_at: :desc).page(params[:page])
    else
      Survey.active.order(created_at: :desc).page(params[:page])
    end
  end

  # GET /surveys/new - サーベイ作成（管理者のみ）
  def new
    @survey = Survey.new
  end

  # POST /surveys - 作成
  # params: title, survey_type, deadline, target_department（部門で一括選択）, target_saas_ids（対象SaaS）
  def create
    @survey = Survey.new(survey_params)
    @survey.created_by = current_user
    if @survey.save
      generate_responses(@survey)
      redirect_to @survey, notice: "サーベイを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /surveys/:id - 詳細
  # 管理者: 回答状況一覧・集計結果
  # 一般: 自分の回答フォーム
  def show
    @survey = Survey.find(params[:id])
    if current_user.admin?
      @responses = @survey.survey_responses.includes(:user, saas_account: :saas)
    else
      @my_responses = @survey.survey_responses.where(user: current_user).includes(saas_account: :saas)
    end
  end

  # PATCH /surveys/:id/close - サーベイ締め切り
  def close
    survey = Survey.find(params[:id])
    survey.update!(status: :closed)
    redirect_to survey, notice: "サーベイを締め切りました"
  end

  # POST /surveys/:id/activate - サーベイ配信（draft → active）
  def activate
    survey = Survey.find(params[:id])
    survey.update!(status: :active, sent_at: Time.current)
    TeamsNotifier.notify(
      title: "アカウントサーベイのお願い",
      body: "「#{survey.title}」への回答をお願いします。\n期限: #{survey.deadline&.strftime('%Y/%m/%d')}"
    )
    redirect_to survey, notice: "サーベイを配信しました"
  end

  # POST /surveys/:id/remind - リマインド送信
  def remind
    survey = Survey.find(params[:id])
    pending_count = survey.survey_responses.pending.select(:user_id).distinct.count
    TeamsNotifier.notify(
      title: "【リマインド】アカウントサーベイ未回答",
      body: "「#{survey.title}」に#{pending_count}名が未回答です。\n期限: #{survey.deadline&.strftime('%Y/%m/%d')}"
    )
    redirect_to survey, notice: "リマインドを送信しました"
  end

  private

  def survey_params
    params.require(:survey).permit(:title, :survey_type, :deadline, :target_department, target_saas_ids: [])
  end

  # 対象メンバー × 対象SaaS のレスポンスレコードを事前生成
  def generate_responses(survey)
    target_saas_ids = params.dig(:survey, :target_saas_ids)&.reject(&:blank?)
    department = params.dig(:survey, :target_department)

    accounts = SaasAccount.where(status: "active").includes(:user, :saas)
    accounts = accounts.where(saas_id: target_saas_ids) if target_saas_ids.present?
    accounts = accounts.joins(:user).where(users: { department: department }) if department.present?

    accounts.find_each do |account|
      survey.survey_responses.create!(
        user: account.user,
        saas_account: account
      )
    end
  end
end
```

### 2.5 SurveyResponsesController

```ruby
class SurveyResponsesController < ApplicationController
  # PATCH /survey_responses/:id - 回答
  def update
    response = SurveyResponse.find(params[:id])
    # 自分のレスポンスのみ回答可能
    unless response.user == current_user
      redirect_to surveys_path, alert: "権限がありません"
      return
    end
    response.update!(response_params.merge(responded_at: Time.current))
    redirect_to survey_path(response.survey), notice: "回答を保存しました"
  end

  private

  def response_params
    params.require(:survey_response).permit(:response, :notes)
  end
end
```

### 2.6 ルーティング

```ruby
resources :surveys, only: [:index, :new, :create, :show] do
  member do
    patch :close
    post :activate
    post :remind
  end
end
resources :survey_responses, only: [:update]
```

### 2.7 画面構成

| パス | 内容 |
|------|------|
| GET /surveys | サーベイ一覧（管理者: 全件、一般: active のみ） |
| GET /surveys/new | サーベイ作成（対象SaaS選択・対象部門選択・期限） |
| GET /surveys/:id | 管理者: 回答状況ダッシュボード / 一般: 回答フォーム |
| PATCH /surveys/:id/close | 締め切り |
| POST /surveys/:id/activate | 配信（draft→active） |
| POST /surveys/:id/remind | リマインド送信 |
| PATCH /survey_responses/:id | 回答保存 |

---

## Step 3: 入退社タスク管理

### 3.1 task_presets マイグレーション

```ruby
create_table :task_presets do |t|
  t.string :name, null: false
  t.string :task_type, null: false  # onboarding / offboarding / transfer
  t.text :description
  t.timestamps
end
```

### 3.2 task_preset_items マイグレーション

```ruby
create_table :task_preset_items do |t|
  t.references :task_preset, null: false, foreign_key: true
  t.string :action_type, null: false  # account_create / account_delete / pc_return 等
  t.string :description, null: false
  t.references :default_assignee, foreign_key: { to_table: :users }
  t.integer :position, default: 0
  t.timestamps
end
```

### 3.3 tasks マイグレーション

```ruby
create_table :tasks do |t|
  t.string :title, null: false
  t.string :task_type, null: false  # onboarding / offboarding / transfer
  t.references :target_user, null: false, foreign_key: { to_table: :users }
  t.references :created_by, null: false, foreign_key: { to_table: :users }
  t.string :status, null: false, default: "open"  # open / in_progress / completed
  t.date :due_date
  t.timestamps
end

add_index :tasks, :status
```

### 3.4 task_items マイグレーション

```ruby
create_table :task_items do |t|
  t.references :task, null: false, foreign_key: true
  t.string :action_type, null: false
  t.string :description, null: false
  t.references :saas, foreign_key: { to_table: :saases }
  t.references :assignee, foreign_key: { to_table: :users }
  t.string :status, null: false, default: "pending"  # pending / completed
  t.datetime :completed_at
  t.text :notes
  t.timestamps
end

add_index :task_items, :status
```

### 3.5 モデル

```ruby
# task_preset.rb
class TaskPreset < ApplicationRecord
  has_many :task_preset_items, dependent: :destroy
  accepts_nested_attributes_for :task_preset_items, allow_destroy: true

  enum :task_type, { onboarding: "onboarding", offboarding: "offboarding", transfer: "transfer" }
  validates :name, presence: true
end

# task_preset_item.rb
class TaskPresetItem < ApplicationRecord
  belongs_to :task_preset
  belongs_to :default_assignee, class_name: "User", optional: true
  validates :action_type, presence: true
  validates :description, presence: true
end

# task.rb (名前衝突回避のため LifecycleTask にする可能性あり → Railsの既存Taskと衝突しないか確認)
class Task < ApplicationRecord
  belongs_to :target_user, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :task_items, dependent: :destroy

  enum :task_type, { onboarding: "onboarding", offboarding: "offboarding", transfer: "transfer" }
  enum :status, { open: "open", in_progress: "in_progress", completed: "completed" }

  validates :title, presence: true

  def completion_rate
    return 0 if task_items.count.zero?
    (task_items.where(status: "completed").count.to_f / task_items.count * 100).round(1)
  end
end

# task_item.rb
class TaskItem < ApplicationRecord
  belongs_to :task
  belongs_to :saas, class_name: "Saas", optional: true
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { pending: "pending", completed: "completed" }

  def complete!
    update!(status: :completed, completed_at: Time.current)
  end
end
```

### 3.6 TaskPresetsController

```ruby
class TaskPresetsController < ApplicationController
  before_action :require_admin

  def index
    @presets = TaskPreset.all.order(:task_type, :name)
  end

  def new
    @preset = TaskPreset.new
    @preset.task_preset_items.build
  end

  def create
    @preset = TaskPreset.new(preset_params)
    if @preset.save
      redirect_to task_presets_path, notice: "プリセットを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @preset = TaskPreset.find(params[:id])
  end

  def update
    @preset = TaskPreset.find(params[:id])
    if @preset.update(preset_params)
      redirect_to task_presets_path, notice: "プリセットを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    TaskPreset.find(params[:id]).destroy!
    redirect_to task_presets_path, notice: "プリセットを削除しました"
  end

  private

  def preset_params
    params.require(:task_preset).permit(
      :name, :task_type, :description,
      task_preset_items_attributes: [:id, :action_type, :description, :default_assignee_id, :position, :_destroy]
    )
  end
end
```

### 3.7 TasksController

```ruby
class TasksController < ApplicationController
  before_action :require_admin, only: [:new, :create]

  def index
    @tasks = Task.includes(:target_user, :created_by)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.where(task_type: params[:task_type]) if params[:task_type].present?
    @tasks = @tasks.order(created_at: :desc).page(params[:page])
  end

  # GET /tasks/new?preset_id=1&target_user_id=2
  def new
    @task = Task.new
    @presets = TaskPreset.all
    @users = User.order(:display_name)

    if params[:preset_id].present? && params[:target_user_id].present?
      preset = TaskPreset.find(params[:preset_id])
      target_user = User.find(params[:target_user_id])
      @task.title = "#{target_user.display_name}の#{preset.name}"
      @task.task_type = preset.task_type
      @task.target_user = target_user
      @task.due_date = 2.weeks.from_now.to_date

      # プリセット項目からタスクアイテムを生成
      preset.task_preset_items.each do |item|
        @task.task_items.build(
          action_type: item.action_type,
          description: item.description,
          assignee: item.default_assignee
        )
      end

      # 退職処理の場合、対象者のSaaSアカウントを自動列挙
      if preset.offboarding?
        target_user.saas_accounts.where(status: "active").includes(:saas).each do |account|
          @task.task_items.build(
            action_type: "account_delete",
            description: "#{account.saas.name} アカウント削除",
            saas: account.saas
          )
        end
      end

      # 入社処理の場合、主要SaaSのアカウント作成を列挙
      if preset.onboarding?
        Saas.where(status: "active").each do |saas|
          @task.task_items.build(
            action_type: "account_create",
            description: "#{saas.name} アカウント作成",
            saas: saas
          )
        end
      end
    end
  end

  def create
    @task = Task.new(task_params)
    @task.created_by = current_user
    if @task.save
      TeamsNotifier.notify(
        title: "新しいタスクが作成されました",
        body: "「#{@task.title}」\n期限: #{@task.due_date}\n項目数: #{@task.task_items.count}"
      )
      redirect_to @task, notice: "タスクを作成しました"
    else
      @presets = TaskPreset.all
      @users = User.order(:display_name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @task = Task.find(params[:id])
    @task_items = @task.task_items.includes(:saas, :assignee).order(:id)
  end

  private

  def task_params
    params.require(:task).permit(
      :title, :task_type, :target_user_id, :due_date,
      task_items_attributes: [:action_type, :description, :saas_id, :assignee_id]
    )
  end
end
```

### 3.8 TaskItemsController

```ruby
class TaskItemsController < ApplicationController
  # PATCH /task_items/:id
  def update
    item = TaskItem.find(params[:id])
    if params[:complete] == "true"
      item.complete!
    else
      item.update!(status: :pending, completed_at: nil)
    end

    task = item.task
    # 全アイテム完了ならタスクも完了に
    if task.task_items.all? { |i| i.completed? }
      task.update!(status: :completed)
    elsif task.open?
      task.update!(status: :in_progress)
    end

    redirect_to task_path(task)
  end
end
```

### 3.9 ルーティング

```ruby
resources :task_presets
resources :tasks, only: [:index, :new, :create, :show]
resources :task_items, only: [:update]
```

### 3.10 画面構成

| パス | 内容 |
|------|------|
| GET /task_presets | プリセット一覧（admin） |
| GET /task_presets/new | プリセット作成 |
| GET /task_presets/:id/edit | プリセット編集 |
| GET /tasks | タスク一覧（ステータス・種類フィルタ） |
| GET /tasks/new | タスク作成（プリセット選択 → SaaS自動列挙） |
| GET /tasks/:id | タスク詳細（チェックリスト形式） |
| PATCH /task_items/:id | アイテム完了/未完了切替 |

---

## Step 4: SaaS利用申請・承認フロー

### 4.1 approval_requests マイグレーション

```ruby
create_table :approval_requests do |t|
  t.string :request_type, null: false, default: "add_account"
    # new_saas / add_account / remove_account
  t.references :requester, null: false, foreign_key: { to_table: :users }
  t.references :saas, foreign_key: { to_table: :saases }  # 既存SaaSの場合
  t.string :saas_name                                       # 新規SaaSの場合
  t.text :reason
  t.integer :estimated_cost                                 # 費用概算（円/月）
  t.integer :user_count                                     # 利用人数
  t.string :status, null: false, default: "pending"        # pending / approved / rejected
  t.references :approved_by, foreign_key: { to_table: :users }
  t.datetime :approved_at
  t.text :rejection_reason
  t.timestamps
end

add_index :approval_requests, :status
```

### 4.2 モデル

```ruby
# approval_request.rb
class ApprovalRequest < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :saas, class_name: "Saas", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  enum :request_type, { new_saas: "new_saas", add_account: "add_account", remove_account: "remove_account" }
  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }

  validates :reason, presence: true

  def target_saas_name
    saas&.name || saas_name
  end
end
```

### 4.3 ApprovalRequestsController

```ruby
class ApprovalRequestsController < ApplicationController
  # GET /approval_requests - 自分の申請一覧（admin: 全件 + 承認待ちタブ）
  def index
    if current_user.admin? || current_user.manager?
      @pending_requests = ApprovalRequest.pending.includes(:requester, :saas).order(created_at: :desc)
      @all_requests = ApprovalRequest.includes(:requester, :saas).order(created_at: :desc).page(params[:page])
    else
      @all_requests = ApprovalRequest.where(requester: current_user).order(created_at: :desc).page(params[:page])
    end
  end

  # GET /approval_requests/new
  def new
    @approval_request = ApprovalRequest.new
    @saases = Saas.where(status: "active").order(:name)
  end

  # POST /approval_requests
  def create
    @approval_request = ApprovalRequest.new(request_params)
    @approval_request.requester = current_user
    if @approval_request.save
      TeamsNotifier.notify(
        title: "SaaS利用申請",
        body: "#{current_user.display_name}さんから申請があります。\n種別: #{@approval_request.request_type}\n対象: #{@approval_request.target_saas_name}\n理由: #{@approval_request.reason}"
      )
      redirect_to approval_requests_path, notice: "申請を送信しました"
    else
      @saases = Saas.where(status: "active").order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /approval_requests/:id
  def show
    @approval_request = ApprovalRequest.find(params[:id])
  end

  # POST /approval_requests/:id/approve
  def approve
    request = ApprovalRequest.find(params[:id])
    unless current_user.admin? || current_user.manager?
      redirect_to approval_requests_path, alert: "承認権限がありません"
      return
    end
    request.update!(
      status: :approved,
      approved_by: current_user,
      approved_at: Time.current
    )
    TeamsNotifier.notify(
      title: "申請が承認されました",
      body: "「#{request.target_saas_name}」の利用申請が#{current_user.display_name}によって承認されました。"
    )
    redirect_to approval_request_path(request), notice: "承認しました"
  end

  # POST /approval_requests/:id/reject
  def reject
    request = ApprovalRequest.find(params[:id])
    unless current_user.admin? || current_user.manager?
      redirect_to approval_requests_path, alert: "承認権限がありません"
      return
    end
    request.update!(
      status: :rejected,
      approved_by: current_user,
      approved_at: Time.current,
      rejection_reason: params[:rejection_reason]
    )
    TeamsNotifier.notify(
      title: "申請が却下されました",
      body: "「#{request.target_saas_name}」の利用申請が却下されました。\n理由: #{request.rejection_reason}"
    )
    redirect_to approval_request_path(request), notice: "却下しました"
  end

  private

  def request_params
    params.require(:approval_request).permit(:request_type, :saas_id, :saas_name, :reason, :estimated_cost, :user_count)
  end
end
```

### 4.4 ルーティング

```ruby
resources :approval_requests, only: [:index, :new, :create, :show] do
  member do
    post :approve
    post :reject
  end
end
```

### 4.5 画面構成

| パス | 内容 |
|------|------|
| GET /approval_requests | 申請一覧（admin/manager: 承認待ちタブ + 全件、一般: 自分の申請） |
| GET /approval_requests/new | 申請フォーム（種別・SaaS選択・理由・費用概算・利用人数） |
| GET /approval_requests/:id | 申請詳細（承認/却下ボタン・タイムライン） |
| POST /approval_requests/:id/approve | 承認 |
| POST /approval_requests/:id/reject | 却下（理由入力） |

---

## Step 5: Seed データ追加

フェーズ3の機能用デモデータを追加:

- タスクプリセット 3件（入社処理・退職処理・異動処理）
  - 各プリセットに3〜5個のテンプレート項目
- サンプルサーベイ 1件（完了済み、回答あり）
- サンプル申請 3件（pending, approved, rejected）
- サンプルタスク 2件（1件完了、1件進行中）

---

## Step 6: サイドバー & ダッシュボード更新

- サイドバーの disabled リンクを有効化（サーベイ・タスク管理・申請承認・バッチ管理）
- ダッシュボードに追加:
  - 承認待ち申請数
  - 進行中タスク数
  - アクティブサーベイ数

---

## Step 7: RSpec テスト

### モデルスペック
- `spec/models/batch_execution_log_spec.rb`
- `spec/models/survey_spec.rb`
- `spec/models/survey_response_spec.rb`
- `spec/models/task_preset_spec.rb`
- `spec/models/task_spec.rb` (+ task_item, task_preset_item)
- `spec/models/approval_request_spec.rb`

### リクエストスペック
- `spec/requests/admin/batches_spec.rb`
- `spec/requests/surveys_spec.rb`
- `spec/requests/survey_responses_spec.rb`
- `spec/requests/task_presets_spec.rb`
- `spec/requests/tasks_spec.rb`
- `spec/requests/task_items_spec.rb`
- `spec/requests/approval_requests_spec.rb`

### ジョブスペック
- `spec/jobs/entra_user_sync_job_spec.rb`（Graph APIはモック）
- `spec/jobs/retired_account_detection_job_spec.rb`

### サービススペック
- `spec/services/entra_client_spec.rb`（HTTP通信はモック）
- `spec/services/teams_notifier_spec.rb`（HTTP通信はモック）

---

## 成果物チェックリスト

### Step 1: バッチ基盤 & 退職者検出
- [x] batch_execution_logs マイグレーション & モデル
- [x] EntraClient サービス
- [x] TeamsNotifier サービス
- [x] EntraUserSyncJob
- [x] RetiredAccountDetectionJob
- [x] Admin::BatchesController & ビュー
- [x] ルーティング（admin namespace）
- [x] サイドバーのバッチ管理リンク有効化

### Step 2: アカウントサーベイ
- [x] surveys マイグレーション & モデル
- [x] survey_responses マイグレーション & モデル
- [x] SurveysController（一覧・作成・詳細・配信・締切・リマインド）
- [x] SurveyResponsesController（回答）
- [x] ビュー（一覧・作成フォーム・管理者結果画面・メンバー回答画面）
- [x] ルーティング
- [x] サイドバーのサーベイリンク有効化

### Step 3: 入退社タスク管理
- [x] task_presets / task_preset_items マイグレーション & モデル
- [x] tasks / task_items マイグレーション & モデル
- [x] TaskPresetsController（CRUD）
- [x] TasksController（一覧・作成・詳細）
- [x] TaskItemsController（完了/未完了切替）
- [x] ビュー（プリセット管理・タスク一覧・タスク作成・チェックリスト詳細）
- [x] ルーティング
- [x] サイドバーのタスク管理リンク有効化

### Step 4: SaaS利用申請・承認
- [x] approval_requests マイグレーション & モデル
- [x] ApprovalRequestsController（申請・一覧・詳細・承認・却下）
- [x] ビュー（申請フォーム・一覧・詳細＋承認/却下）
- [x] ルーティング
- [x] サイドバーの申請・承認リンク有効化

### Step 5: Seed & ダッシュボード
- [x] Seed データ追加
- [x] ダッシュボード サマリー更新
- [x] サイドバー全リンク有効化

### Step 6: テスト
- [x] FactoryBot 定義（全新規モデル）
- [x] モデルスペック
- [x] リクエストスペック
- [x] ジョブスペック
- [x] サービススペック
- [x] `bundle exec rspec` 全121テストパス

### 実装時の補足
- `Task` モデル名はRails内部の `Rake::Task` と衝突しないことを確認済み
- TeamsNotifier は `ENV["TEAMS_WEBHOOK_URL"]` で設定（.env に追加可能）
- webmock gem を追加してHTTP通信をモック化
- EntraUserSyncJob 完了後に RetiredAccountDetectionJob を自動起動する連鎖実行
- 操作ログ（audit_logs）はフェーズ4で実装予定（サイドバーにdisabledで残置）
