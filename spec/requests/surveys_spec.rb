require "rails_helper"

RSpec.describe "Surveys", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:viewer) { create(:user) }

  describe "GET /surveys" do
    it "adminは全サーベイを表示" do
      login_as(admin)
      create(:survey, title: "テストサーベイ", created_by: admin)
      get surveys_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テストサーベイ")
    end

    it "viewerはactiveのサーベイのみ表示" do
      login_as(viewer)
      create(:survey, title: "下書き", status: "draft", created_by: admin)
      create(:survey, title: "配信中", status: "active", created_by: admin)
      get surveys_path
      expect(response.body).not_to include("下書き")
      expect(response.body).to include("配信中")
    end
  end

  describe "GET /surveys/new" do
    it "adminは作成画面にアクセスできる" do
      login_as(admin)
      get new_survey_path
      expect(response).to have_http_status(:ok)
    end

    it "viewerはリダイレクトされる" do
      login_as(viewer)
      get new_survey_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /surveys" do
    it "サーベイを作成できる" do
      login_as(admin)
      expect {
        post surveys_path, params: {
          survey: { title: "新規サーベイ", survey_type: "account_review", deadline: 2.weeks.from_now.to_date }
        }
      }.to change(Survey, :count).by(1)
    end
  end

  describe "GET /surveys/:id" do
    it "adminは結果画面を表示" do
      login_as(admin)
      survey = create(:survey, status: "active", created_by: admin)
      get survey_path(survey)
      expect(response).to have_http_status(:ok)
    end

    it "viewerは回答画面を表示" do
      login_as(viewer)
      survey = create(:survey, status: "active", created_by: admin)
      get survey_path(survey)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /surveys/:id/activate" do
    it "サーベイを配信できる" do
      login_as(admin)
      survey = create(:survey, status: "draft", created_by: admin)
      post activate_survey_path(survey)
      expect(survey.reload).to be_active
      expect(survey.sent_at).to be_present
    end
  end

  describe "PATCH /surveys/:id/close" do
    it "サーベイを締め切れる" do
      login_as(admin)
      survey = create(:survey, status: "active", created_by: admin)
      patch close_survey_path(survey)
      expect(survey.reload).to be_closed
    end
  end

  describe "POST /surveys/:id/create_cleanup_task" do
    let(:survey) { create(:survey, status: "closed", created_by: admin) }
    let(:saas) { create(:saas, name: "Slack") }
    let(:user1) { create(:user, display_name: "田中 一郎") }

    it "not_using回答から削除タスクを生成する" do
      login_as(admin)
      account = create(:saas_account, saas: saas, user: user1)
      create(:survey_response, survey: survey, user: user1, saas_account: account, response: "not_using", responded_at: 1.day.ago)

      expect {
        post create_cleanup_task_survey_path(survey)
      }.to change(Task, :count).by(1)
       .and change(TaskItem, :count).by(1)

      task = Task.last
      expect(task.task_type).to eq("account_cleanup")
      expect(task.task_items.first.action_type).to eq("account_delete")
      expect(task.task_items.first.saas).to eq(saas)
      expect(response).to redirect_to(survey_path(survey))
    end

    it "not_using回答がなければタスクを作成しない" do
      login_as(admin)
      account = create(:saas_account, saas: saas, user: user1)
      create(:survey_response, survey: survey, user: user1, saas_account: account, response: "using", responded_at: 1.day.ago)

      expect {
        post create_cleanup_task_survey_path(survey)
      }.not_to change(Task, :count)
    end

    it "viewerはアクセスできない" do
      login_as(viewer)
      post create_cleanup_task_survey_path(survey)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /surveys/:id（不要アカウント表示）" do
    it "adminはnot_using回答のある詳細画面に不要アカウントセクションが表示される" do
      login_as(admin)
      survey = create(:survey, status: "closed", created_by: admin)
      saas = create(:saas, name: "TestSaaS")
      user1 = create(:user)
      account = create(:saas_account, saas: saas, user: user1)
      create(:survey_response, survey: survey, user: user1, saas_account: account, response: "not_using", responded_at: 1.day.ago)

      get survey_path(survey)
      expect(response.body).to include("不要アカウント")
      expect(response.body).to include("削除タスクを生成")
    end
  end
end
