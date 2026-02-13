require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "未ログインはログイン画面にリダイレクト" do
      get root_path
      expect(response).to redirect_to(login_path)
    end

    it "ログイン済みはダッシュボードを表示" do
      user = create(:user)
      post dev_login_path, params: { email: user.email, display_name: user.display_name }
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ダッシュボード")
    end
  end

  describe "契約更新アラート" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "30日以内に期限が来る契約を表示する" do
      saas = create(:saas, name: "Slack")
      create(:saas_contract, saas: saas, expires_on: 10.days.from_now.to_date)

      get root_path
      expect(response.body).to include("契約更新アラート")
      expect(response.body).to include("Slack")
    end

    it "期限切れ契約の件数を表示する" do
      saas = create(:saas, name: "Zoom")
      create(:saas_contract, saas: saas, expires_on: 5.days.ago.to_date)

      get root_path
      expect(response.body).to include("期限切れ")
    end

    it "該当する契約がなければアラートセクションを表示しない" do
      get root_path
      expect(response.body).not_to include("契約更新アラート")
    end
  end
end
