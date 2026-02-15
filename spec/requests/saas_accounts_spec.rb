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

  describe "POST /saas_accounts/import" do
    let!(:slack) { create(:saas, name: "Slack") }
    let!(:user1) { create(:user, email: "user1@example.com") }
    let!(:user2) { create(:user, email: "user2@example.com") }
    let(:csv_file) { fixture_file_upload("saas_account_import.csv", "text/csv") }

    it "CSVからアカウントを一括登録する" do
      expect {
        post import_saas_accounts_path, params: { file: csv_file }
      }.to change(SaasAccount, :count).by(2)
      expect(response).to redirect_to(saas_accounts_path)
      follow_redirect!
      expect(response.body).to include("2件のアカウントをインポートしました")
    end

    it "ファイル未選択でエラーメッセージを表示する" do
      post import_saas_accounts_path
      expect(response).to redirect_to(saas_accounts_path)
      follow_redirect!
      expect(response.body).to include("ファイルを選択してください")
    end

    context "viewer権限の場合" do
      let(:user) { create(:user) } # role: viewer

      it "ダッシュボードにリダイレクトされる" do
        post import_saas_accounts_path, params: { file: csv_file }
        expect(response).to redirect_to(root_path)
      end
    end

    context "manager権限の場合" do
      let(:user) { create(:user, :manager) }

      it "インポートを実行できる" do
        expect {
          post import_saas_accounts_path, params: { file: csv_file }
        }.to change(SaasAccount, :count).by(2)
      end
    end
  end

  describe "GET /saas_accounts/download_template" do
    it "CSVテンプレートをダウンロードできる" do
      get download_template_saas_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("saas_account_template.csv")
      expect(response.body).to include("saas_name,user_email")
    end
  end

  describe "GET /saas_accounts/export" do
    it "CSV形式でエクスポートできる" do
      saas = create(:saas, name: "Slack")
      create(:saas_account, saas: saas, user: user, account_email: "admin@slack.com")

      get export_saas_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("saas_accounts_export")
      expect(response.body).to include("Slack")
      expect(response.body).to include("admin@slack.com")
    end

    it "SaaSで絞り込んでエクスポートできる" do
      saas1 = create(:saas, name: "Slack")
      saas2 = create(:saas, name: "Zoom")
      create(:saas_account, saas: saas1, user: user)
      other_user = create(:user)
      create(:saas_account, saas: saas2, user: other_user)

      get export_saas_accounts_path, params: { saas_id: saas1.id }
      expect(response.body).to include("Slack")
      expect(response.body).not_to include("Zoom")
    end
  end
end
