require "rails_helper"

RSpec.describe "Saases", type: :request do
  let(:user) { create(:user, :admin) }

  before { login_as(user) }

  describe "GET /saases" do
    it "一覧を表示" do
      create(:saas, name: "Slack")
      get saases_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Slack")
    end

    it "名前で検索" do
      create(:saas, name: "Slack")
      create(:saas, name: "Zoom")
      get saases_path, params: { q: "Slack" }
      expect(response.body).to include("Slack")
      expect(response.body).not_to include("Zoom")
    end

    it "カテゴリで絞り込み" do
      create(:saas, name: "Slack", category: "一般")
      create(:saas, name: "いえらぶ", category: "不動産管理")
      get saases_path, params: { category: "一般" }
      expect(response.body).to include("Slack")
      expect(response.body).not_to include("いえらぶ")
    end
  end

  describe "GET /saases/:id" do
    it "詳細を表示" do
      saas = create(:saas, name: "Slack")
      get saas_path(saas)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Slack")
    end
  end

  describe "POST /saases" do
    it "SaaSを作成" do
      expect {
        post saases_path, params: { saas: { name: "New SaaS", category: "一般" } }
      }.to change(Saas, :count).by(1)
      expect(response).to redirect_to(saas_path(Saas.last))
    end

    it "バリデーションエラーでフォーム再表示" do
      post saases_path, params: { saas: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /saases/:id" do
    it "SaaSを更新" do
      saas = create(:saas, name: "Old Name")
      patch saas_path(saas), params: { saas: { name: "New Name" } }
      expect(saas.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /saases/:id" do
    it "SaaSを削除" do
      saas = create(:saas)
      expect {
        delete saas_path(saas)
      }.to change(Saas, :count).by(-1)
    end
  end
end
