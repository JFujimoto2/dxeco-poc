require "rails_helper"

RSpec.describe "SurveyResponses", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /survey_responses/:id" do
    it "自分の回答を更新できる" do
      login_as(user)
      survey = create(:survey, status: "active")
      account = create(:saas_account, user: user)
      response = create(:survey_response, survey: survey, user: user, saas_account: account)

      patch survey_response_path(response), params: {
        survey_response: { response: "using", notes: "利用中です" }
      }
      response.reload
      expect(response.response).to eq("using")
      expect(response.responded_at).to be_present
    end

    it "他人の回答は更新できない" do
      login_as(user)
      other_user = create(:user)
      survey = create(:survey, status: "active")
      account = create(:saas_account, user: other_user)
      resp = create(:survey_response, survey: survey, user: other_user, saas_account: account)

      patch survey_response_path(resp), params: {
        survey_response: { response: "not_using" }
      }
      expect(response).to redirect_to(surveys_path)
    end
  end
end
