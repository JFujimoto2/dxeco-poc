require "rails_helper"

RSpec.describe "Tasks", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /tasks" do
    it "一覧を表示" do
      target = create(:user)
      create(:task, title: "山田の退職処理", created_by: admin, target_user: target)
      get tasks_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("山田の退職処理")
    end

    it "ステータスで絞り込み" do
      target = create(:user)
      create(:task, title: "進行中タスク", status: "in_progress", created_by: admin, target_user: target)
      create(:task, title: "完了タスク", status: "completed", created_by: admin, target_user: target)
      get tasks_path, params: { status: "in_progress" }
      expect(response.body).to include("進行中タスク")
      expect(response.body).not_to include("完了タスク")
    end
  end

  describe "GET /tasks/new" do
    it "作成画面を表示" do
      get new_task_path
      expect(response).to have_http_status(:ok)
    end

    it "プリセットとユーザーを指定してタスクを展開" do
      preset = create(:task_preset, name: "退職処理", task_type: "offboarding")
      create(:task_preset_item, task_preset: preset, action_type: "account_delete", description: "全アカウント削除")
      target = create(:user, display_name: "退職者太郎")
      saas = create(:saas, name: "Slack", status: "active")
      create(:saas_account, user: target, saas: saas, status: "active")

      get new_task_path, params: { preset_id: preset.id, target_user_id: target.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("退職者太郎の退職処理")
      expect(response.body).to include("Slack アカウント削除")
    end

    it "onboardingプリセットで全SaaSを展開" do
      preset = create(:task_preset, name: "入社処理", task_type: "onboarding")
      target = create(:user, display_name: "新人太郎")
      create(:saas, name: "GitHub", status: "active")

      get new_task_path, params: { preset_id: preset.id, target_user_id: target.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("GitHub アカウント作成")
    end
  end

  describe "GET /tasks (タイプフィルタ)" do
    it "task_typeで絞り込み" do
      target = create(:user)
      create(:task, title: "退職タスク", task_type: "offboarding", created_by: admin, target_user: target)
      create(:task, title: "入社タスク", task_type: "onboarding", created_by: admin, target_user: target)
      get tasks_path, params: { task_type: "offboarding" }
      expect(response.body).to include("退職タスク")
      expect(response.body).not_to include("入社タスク")
    end
  end

  describe "POST /tasks" do
    it "タスクを作成" do
      target = create(:user)
      expect {
        post tasks_path, params: {
          task: {
            title: "テストタスク", task_type: "offboarding",
            target_user_id: target.id, due_date: 2.weeks.from_now.to_date,
            task_items_attributes: [
              { action_type: "account_delete", description: "Slackアカウント削除" }
            ]
          }
        }
      }.to change(Task, :count).by(1)
    end
  end

  describe "GET /tasks/:id" do
    it "詳細を表示" do
      target = create(:user)
      task = create(:task, created_by: admin, target_user: target)
      create(:task_item, task: task, description: "Slack削除")
      get task_path(task)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Slack削除")
    end
  end
end
