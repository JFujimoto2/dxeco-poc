require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /users" do
    it "一覧を表示" do
      create(:user, display_name: "田中太郎")
      get users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("田中太郎")
    end

    it "名前で検索" do
      create(:user, display_name: "田中太郎")
      create(:user, display_name: "鈴木花子")
      get users_path, params: { q: "田中" }
      expect(response.body).to include("田中太郎")
      expect(response.body).not_to include("鈴木花子")
    end
  end

  describe "GET /users/:id" do
    it "詳細を表示" do
      target = create(:user, display_name: "田中太郎")
      get user_path(target)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("田中太郎")
    end
  end

  describe "PATCH /users/:id" do
    it "adminがロールを更新" do
      target = create(:user, role: "viewer")
      patch user_path(target), params: { user: { role: "manager" } }
      expect(target.reload).to be_manager
    end

    it "viewerは編集できない" do
      viewer = create(:user, role: "viewer")
      login_as(viewer)
      target = create(:user)
      patch user_path(target), params: { user: { role: "admin" } }
      expect(response).to redirect_to(root_path)
    end
  end
end
