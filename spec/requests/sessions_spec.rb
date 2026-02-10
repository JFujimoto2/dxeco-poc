require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "ログイン画面を表示" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /dev_login" do
    it "新規ユーザーで開発ログインできる" do
      post dev_login_path, params: { email: "test@example.com", display_name: "テスト" }
      expect(response).to redirect_to(root_path)
      expect(User.find_by(email: "test@example.com")).to be_present
    end

    it "既存ユーザーで開発ログインできる" do
      user = create(:user)
      post dev_login_path, params: { email: user.email, display_name: user.display_name }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /logout" do
    it "ログアウトしてログイン画面にリダイレクト" do
      post dev_login_path, params: { email: "test@example.com", display_name: "テスト" }
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
