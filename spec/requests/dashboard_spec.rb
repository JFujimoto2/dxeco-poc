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
end
