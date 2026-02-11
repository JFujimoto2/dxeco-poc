require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "ログイン画面を表示" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /auth/entra_id/callback (SSO)" do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:entra_id] = OmniAuth::AuthHash.new(
        provider: "entra_id",
        uid: "entra-sso-123",
        info: { email: "sso@example.com", name: "SSO太郎" },
        credentials: { token: "mock-access-token" },
        extra: { raw_info: { "oid" => "entra-oid-456" } }
      )
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:entra_id] = nil
    end

    it "SSOログイン時にGraph APIからプロフィールを取得する" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me?$select=department,jobTitle,employeeId")
        .to_return(status: 200, body: {
          "department" => "営業部",
          "jobTitle" => "課長",
          "employeeId" => "EMP042"
        }.to_json)

      get "/auth/entra_id/callback"
      user = User.find_by(entra_id_sub: "entra-oid-456")
      expect(user.department).to eq("営業部")
      expect(user.job_title).to eq("課長")
      expect(user.employee_id).to eq("EMP042")
    end

    it "entra_id_subにOIDCのsubではなくoidを使用する" do
      stub_request(:get, /graph\.microsoft\.com/).to_return(status: 200, body: "{}".to_json)

      get "/auth/entra_id/callback"
      expect(User.find_by(entra_id_sub: "entra-oid-456")).to be_present
      expect(User.find_by(entra_id_sub: "entra-sso-123")).to be_nil
    end

    it "Graph API失敗時もログインは成功する" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me?$select=department,jobTitle,employeeId")
        .to_return(status: 500, body: "error")

      get "/auth/entra_id/callback"
      expect(response).to redirect_to(root_path)
      expect(User.find_by(entra_id_sub: "entra-oid-456")).to be_present
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
    it "開発ログインの場合はログイン画面にリダイレクト" do
      post dev_login_path, params: { email: "test@example.com", display_name: "テスト" }
      delete logout_path
      expect(response).to redirect_to(login_path)
    end

    it "SSOログインの場合はEntra IDのログアウトにリダイレクト" do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:entra_id] = OmniAuth::AuthHash.new(
        provider: "entra_id", uid: "entra-logout-test",
        info: { email: "sso@example.com", name: "SSO" },
        credentials: { token: "mock-token" }
      )
      stub_request(:get, /graph\.microsoft\.com/).to_return(status: 200, body: "{}".to_json)
      get "/auth/entra_id/callback"

      delete logout_path
      expect(response).to redirect_to(/login\.microsoftonline\.com/)

      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:entra_id] = nil
    end
  end
end
