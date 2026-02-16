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

    it "認証方式で絞り込み" do
      create(:saas, name: "SSO対応", auth_method: "sso")
      create(:saas, name: "パスワード", auth_method: "password")
      get saases_path, params: { auth_method: "sso" }
      expect(response.body).to include("SSO対応")
      expect(response.body).not_to include("パスワード")
    end

    it "データ保存先で絞り込み" do
      create(:saas, name: "国内SaaS", data_location: "domestic")
      create(:saas, name: "海外SaaS", data_location: "overseas")
      get saases_path, params: { data_location: "overseas" }
      expect(response.body).to include("海外SaaS")
      expect(response.body).not_to include("国内SaaS")
    end

    it "部署で絞り込み" do
      sales_user = create(:user, department: "営業部")
      it_user_dept = create(:user, department: "情報システム部")
      saas_a = create(:saas, name: "営業用SaaS")
      saas_b = create(:saas, name: "IT用SaaS")
      create(:saas_account, saas: saas_a, user: sales_user)
      create(:saas_account, saas: saas_b, user: it_user_dept)

      get saases_path, params: { department: "営業部" }
      expect(response.body).to include("営業用SaaS")
      expect(response.body).not_to include("IT用SaaS")
    end
  end

  describe "GET /saases/:id" do
    it "詳細を表示" do
      saas = create(:saas, name: "Slack")
      get saas_path(saas)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Slack")
    end

    it "セキュリティ情報を表示" do
      saas = create(:saas, name: "セキュリティSaaS", handles_personal_data: true, auth_method: "password", data_location: "overseas")
      get saas_path(saas)
      expect(response.body).to include("セキュリティ情報")
      expect(response.body).to include("個人情報取扱い")
      expect(response.body).to include("認証方式")
      expect(response.body).to include("データ保存先")
    end
  end

  describe "POST /saases" do
    it "セキュリティ属性付きでSaaSを作成" do
      expect {
        post saases_path, params: { saas: {
          name: "セキュリティSaaS", category: "一般",
          handles_personal_data: true, auth_method: "sso", data_location: "domestic"
        } }
      }.to change(Saas, :count).by(1)
      saas = Saas.last
      expect(saas.handles_personal_data).to be true
      expect(saas.auth_method).to eq("sso")
      expect(saas.data_location).to eq("domestic")
    end

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

  describe "POST /saases/import" do
    let(:csv_file) { fixture_file_upload("saas_import.csv", "text/csv") }

    it "CSVからSaaSを一括登録する" do
      expect {
        post import_saases_path, params: { file: csv_file }
      }.to change(Saas, :count).by(3)
      expect(response).to redirect_to(saases_path)
      follow_redirect!
      expect(response.body).to include("3件のSaaSをインポートしました")
    end

    it "ファイル未選択でエラーメッセージを表示する" do
      post import_saases_path
      expect(response).to redirect_to(saases_path)
      follow_redirect!
      expect(response.body).to include("ファイルを選択してください")
    end

    context "viewer権限の場合" do
      let(:user) { create(:user) } # role: viewer

      it "ダッシュボードにリダイレクトされる" do
        post import_saases_path, params: { file: csv_file }
        expect(response).to redirect_to(root_path)
      end
    end

    context "manager権限の場合" do
      let(:user) { create(:user, :manager) }

      it "インポートを実行できる" do
        expect {
          post import_saases_path, params: { file: csv_file }
        }.to change(Saas, :count).by(3)
      end
    end
  end

  describe "GET /saases/download_template" do
    it "CSVテンプレートをダウンロードできる" do
      get download_template_saases_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("saas_template.csv")
      expect(response.body).to include("SaaS名,カテゴリ,ステータス")
    end
  end

  describe "GET /saases/export" do
    it "CSV形式でエクスポートできる" do
      saas = create(:saas, name: "Slack", category: "一般IT")
      create(:saas_contract, saas: saas, plan_name: "Business", price_cents: 50000, billing_cycle: "monthly")

      get export_saases_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("saas_export")
      expect(response.body).to include("Slack")
      expect(response.body).to include("Business")
    end

    it "フィルタ条件を適用してエクスポートできる" do
      create(:saas, name: "Slack", category: "一般IT")
      create(:saas, name: "いえらぶ", category: "不動産管理")

      get export_saases_path, params: { category: "一般IT" }
      expect(response.body).to include("Slack")
      expect(response.body).not_to include("いえらぶ")
    end
  end
end
