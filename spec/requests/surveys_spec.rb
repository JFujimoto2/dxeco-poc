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
end
