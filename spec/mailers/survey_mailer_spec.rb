require "rails_helper"

RSpec.describe SurveyMailer do
  let(:admin) { create(:user, :admin, display_name: "管理者") }
  let(:user1) { create(:user, display_name: "ユーザー1", email: "user1@example.com") }
  let(:user2) { create(:user, display_name: "ユーザー2", email: "user2@example.com") }
  let(:saas) { create(:saas, name: "Slack") }
  let(:account1) { create(:saas_account, user: user1, saas: saas) }
  let(:account2) { create(:saas_account, user: user2, saas: saas) }
  let(:survey) { create(:survey, title: "Q1 アカウント棚卸し", created_by: admin, deadline: Date.new(2026, 3, 15)) }

  describe ".distribution" do
    before do
      create(:survey_response, survey: survey, user: user1, saas_account: account1)
      create(:survey_response, survey: survey, user: user2, saas_account: account2)
    end

    let(:mail) { described_class.distribution(survey) }

    it "対象ユーザー全員に送信される" do
      expect(mail.to).to contain_exactly(user1.email, user2.email)
    end

    it "件名にサーベイ名が含まれる" do
      expect(mail.subject).to eq("[SaaS管理] サーベイのお願い: Q1 アカウント棚卸し")
    end

    it "本文にサーベイ情報が含まれる" do
      body = mail.body.encoded
      expect(body).to include("Q1 アカウント棚卸し")
      expect(body).to include("2026/03/15")
    end
  end

  describe ".reminder" do
    before do
      create(:survey_response, survey: survey, user: user1, saas_account: account1, responded_at: nil)
      create(:survey_response, survey: survey, user: user2, saas_account: account2, responded_at: Time.current)
    end

    let(:mail) { described_class.reminder(survey) }

    it "未回答ユーザーのみに送信される" do
      expect(mail.to).to eq([ user1.email ])
    end

    it "件名にリマインドが含まれる" do
      expect(mail.subject).to eq("[SaaS管理] 【リマインド】サーベイ未回答: Q1 アカウント棚卸し")
    end
  end

  describe ".reminder（全員回答済みの場合）" do
    before do
      create(:survey_response, survey: survey, user: user1, saas_account: account1, responded_at: Time.current)
    end

    it "メールが生成されない" do
      mail = described_class.reminder(survey)
      expect(mail.to).to be_nil
    end
  end
end
