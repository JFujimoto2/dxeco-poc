require "rails_helper"

RSpec.describe Survey, type: :model do
  describe "バリデーション" do
    it "バリデーションが通る" do
      survey = build(:survey)
      expect(survey).to be_valid
    end

    it "title が必須" do
      survey = build(:survey, title: nil)
      expect(survey).not_to be_valid
    end
  end

  describe "enum" do
    it "survey_type enumが正しく動作する" do
      %w[account_review password_update].each do |type|
        survey = build(:survey, survey_type: type)
        expect(survey.send("#{type}?")).to be true
      end
    end

    it "status enumが正しく動作する" do
      %w[draft active closed].each do |status|
        survey = build(:survey, status: status)
        expect(survey.status).to eq(status)
      end
    end

    it "無効なsurvey_typeでArgumentErrorが発生する" do
      expect { build(:survey, survey_type: "invalid") }.to raise_error(ArgumentError)
    end

    it "無効なstatusでArgumentErrorが発生する" do
      expect { build(:survey, status: "invalid") }.to raise_error(ArgumentError)
    end
  end

  describe "アソシエーション" do
    it "created_byは必須" do
      survey = build(:survey, created_by: nil)
      expect(survey).not_to be_valid
    end

    it "survey_responsesを持てる" do
      survey = create(:survey)
      user = create(:user)
      account = create(:saas_account)
      response = create(:survey_response, survey: survey, user: user, saas_account: account)
      expect(survey.survey_responses).to include(response)
    end

    it "削除時にsurvey_responsesも削除される" do
      survey = create(:survey)
      user = create(:user)
      account = create(:saas_account)
      create(:survey_response, survey: survey, user: user, saas_account: account)
      expect { survey.destroy }.to change(SurveyResponse, :count).by(-1)
    end
  end

  describe "#response_rate" do
    it "回答率を計算できる" do
      survey = create(:survey)
      user1 = create(:user)
      account1 = create(:saas_account)
      create(:survey_response, survey: survey, user: user1, saas_account: account1, responded_at: Time.current, response: "using")
      user2 = create(:user)
      account2 = create(:saas_account, user: user2, saas: create(:saas))
      create(:survey_response, survey: survey, user: user2, saas_account: account2)
      expect(survey.response_rate).to eq(50.0)
    end

    it "回答が0件の場合0を返す" do
      survey = create(:survey)
      expect(survey.response_rate).to eq(0)
    end

    it "全員回答済みで100.0を返す" do
      survey = create(:survey)
      user = create(:user)
      account = create(:saas_account)
      create(:survey_response, survey: survey, user: user, saas_account: account, responded_at: Time.current, response: "using")
      expect(survey.response_rate).to eq(100.0)
    end
  end

  describe "#target_user_count" do
    it "対象ユーザー数をカウントする" do
      survey = create(:survey)
      user = create(:user)
      saas1 = create(:saas)
      saas2 = create(:saas)
      account1 = create(:saas_account, user: user, saas: saas1)
      account2 = create(:saas_account, user: user, saas: saas2)
      create(:survey_response, survey: survey, user: user, saas_account: account1)
      create(:survey_response, survey: survey, user: user, saas_account: account2)
      # 同一ユーザーは1としてカウント
      expect(survey.target_user_count).to eq(1)
    end
  end

  describe "#responded_user_count" do
    it "回答済みユーザー数をカウントする" do
      survey = create(:survey)
      user1 = create(:user)
      user2 = create(:user)
      account1 = create(:saas_account, user: user1)
      account2 = create(:saas_account, user: user2, saas: create(:saas))
      create(:survey_response, survey: survey, user: user1, saas_account: account1, responded_at: Time.current, response: "using")
      create(:survey_response, survey: survey, user: user2, saas_account: account2, responded_at: nil)
      expect(survey.responded_user_count).to eq(1)
    end
  end
end
