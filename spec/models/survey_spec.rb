require "rails_helper"

RSpec.describe Survey, type: :model do
  it "バリデーションが通る" do
    survey = build(:survey)
    expect(survey).to be_valid
  end

  it "title が必須" do
    survey = build(:survey, title: nil)
    expect(survey).not_to be_valid
  end

  it "ステータスenumが正しく動作する" do
    survey = build(:survey, status: "active")
    expect(survey).to be_active
  end

  it "種別enumが正しく動作する" do
    survey = build(:survey, survey_type: "password_update")
    expect(survey).to be_password_update
  end

  it "response_rateを計算できる" do
    survey = create(:survey)
    user = create(:user)
    account = create(:saas_account)
    create(:survey_response, survey: survey, user: user, saas_account: account, responded_at: Time.current, response: "using")
    user2 = create(:user)
    account2 = create(:saas_account, user: user2, saas: create(:saas))
    create(:survey_response, survey: survey, user: user2, saas_account: account2)
    expect(survey.response_rate).to eq(50.0)
  end
end
