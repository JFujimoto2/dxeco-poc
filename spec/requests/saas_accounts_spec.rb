require "rails_helper"

RSpec.describe "SaasAccounts", type: :request do
  let(:user) { create(:user, :admin) }

  before { login_as(user) }

  describe "GET /saas_accounts" do
    it "一覧を表示" do
      saas = create(:saas, name: "Slack")
      create(:saas_account, saas: saas, user: user)
      get saas_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Slack")
    end

    it "SaaSで絞り込み" do
      saas1 = create(:saas, name: "SlackApp")
      saas2 = create(:saas, name: "ZoomApp")
      create(:saas_account, saas: saas1, user: user)
      other_user = create(:user)
      create(:saas_account, saas: saas2, user: other_user)
      get saas_accounts_path, params: { saas_id: saas1.id }
      # tbody内にSlackAppのリンクがあり、ZoomAppのリンクがないことを確認
      expect(response.body).to include("/saases/#{saas1.id}")
      expect(response.body).not_to include("/saases/#{saas2.id}")
    end
  end

  describe "POST /saas_accounts" do
    it "アカウントを作成" do
      saas = create(:saas)
      target_user = create(:user)
      expect {
        post saas_accounts_path, params: {
          saas_account: { saas_id: saas.id, user_id: target_user.id, account_email: "test@example.com" }
        }
      }.to change(SaasAccount, :count).by(1)
    end
  end

  describe "PATCH /saas_accounts/:id" do
    it "アカウントを更新" do
      account = create(:saas_account, role: "member")
      patch saas_account_path(account), params: { saas_account: { role: "admin" } }
      expect(account.reload.role).to eq("admin")
    end
  end

  describe "DELETE /saas_accounts/:id" do
    it "アカウントを削除" do
      account = create(:saas_account)
      expect {
        delete saas_account_path(account)
      }.to change(SaasAccount, :count).by(-1)
    end
  end
end
