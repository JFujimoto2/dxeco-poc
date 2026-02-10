require "rails_helper"

RSpec.describe SaasAccountImportService do
  let(:file) { Rails.root.join("spec/fixtures/files/saas_account_import.csv") }

  let!(:slack) { create(:saas, name: "Slack") }
  let!(:user1) { create(:user, email: "user1@example.com") }
  let!(:user2) { create(:user, email: "user2@example.com") }

  describe "#call" do
    it "CSVからアカウントを一括登録する" do
      result = SaasAccountImportService.new(file).call
      expect(result[:success_count]).to eq(2)
      expect(result[:error_count]).to eq(0)
    end

    it "SaaS名からsaas_idを解決する" do
      SaasAccountImportService.new(file).call
      account = SaasAccount.find_by(saas: slack, user: user1)
      expect(account).to be_present
      expect(account.role).to eq("member")
    end

    it "存在しないSaaS名はエラーになる" do
      slack.destroy!
      result = SaasAccountImportService.new(file).call
      expect(result[:success_count]).to eq(0)
      expect(result[:error_count]).to eq(2)
    end

    it "存在しないユーザーはエラーになる" do
      user1.destroy!
      result = SaasAccountImportService.new(file).call
      expect(result[:success_count]).to eq(1)
      expect(result[:error_count]).to eq(1)
    end
  end
end
