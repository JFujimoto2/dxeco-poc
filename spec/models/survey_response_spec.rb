require "rails_helper"

RSpec.describe SurveyResponse, type: :model do
  it "バリデーションが通る" do
    response = build(:survey_response)
    expect(response).to be_valid
  end

  it "survey_id + user_id + saas_account_id の一意制約" do
    existing = create(:survey_response)
    dup = build(:survey_response,
      survey: existing.survey,
      user: existing.user,
      saas_account: existing.saas_account
    )
    expect(dup).not_to be_valid
  end

  it "pendingスコープ" do
    create(:survey_response, responded_at: Time.current)
    pending_resp = create(:survey_response, responded_at: nil)
    expect(SurveyResponse.pending).to eq([pending_resp])
  end

  it "respondedスコープ" do
    responded = create(:survey_response, responded_at: Time.current, response: "using")
    create(:survey_response, responded_at: nil)
    expect(SurveyResponse.responded).to eq([responded])
  end
end
