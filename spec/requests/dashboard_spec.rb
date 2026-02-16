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

  describe "パスワード期限アラート" do
    let(:user) { create(:user, :admin) }

    before { login_as(user) }

    it "パスワード期限切れユーザーを表示する" do
      expired_user = create(:user, display_name: "期限切れ太郎", last_password_change_at: 100.days.ago, account_enabled: true)

      get root_path
      expect(response.body).to include("パスワード期限アラート")
      expect(response.body).to include("期限切れ太郎")
    end

    it "パスワード期限間近ユーザーを表示する" do
      expiring_user = create(:user, display_name: "間近花子", last_password_change_at: 80.days.ago, account_enabled: true)

      get root_path
      expect(response.body).to include("パスワード期限アラート")
      expect(response.body).to include("間近花子")
    end

    it "該当ユーザーがいなければアラートセクションを表示しない" do
      get root_path
      expect(response.body).not_to include("パスワード期限アラート")
    end
  end

  describe "セキュリティリスク" do
    let(:user) { create(:user, :admin) }

    before { login_as(user) }

    it "SSO未適用の個人情報SaaS件数を表示する" do
      create(:saas, name: "リスクSaaS", handles_personal_data: true, auth_method: "password")
      create(:saas, name: "安全SaaS", handles_personal_data: true, auth_method: "sso")

      get root_path
      expect(response.body).to include("セキュリティリスク")
      expect(response.body).to include("SSO未適用")
      expect(response.body).to include("リスクSaaS")
    end

    it "海外データ保存の個人情報SaaS件数を表示する" do
      create(:saas, name: "海外個人情報SaaS", handles_personal_data: true, data_location: "overseas")

      get root_path
      expect(response.body).to include("海外データ保存")
      expect(response.body).to include("海外個人情報SaaS")
    end

    it "部門別リスクSaaS利用数を表示する" do
      dept_user = create(:user, department: "営業部")
      risky_saas = create(:saas, name: "リスキーSaaS", handles_personal_data: true, auth_method: "password")
      create(:saas_account, saas: risky_saas, user: dept_user)

      get root_path
      expect(response.body).to include("部門別リスクSaaS")
      expect(response.body).to include("営業部")
    end

    it "リスクがなければセキュリティリスクセクションを表示しない" do
      create(:saas, name: "安全SaaS", handles_personal_data: false)
      get root_path
      expect(response.body).not_to include("セキュリティリスク")
    end
  end

  describe "コスト可視化" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "月額・年額コスト合計を表示する" do
      saas = create(:saas, category: "一般IT")
      create(:saas_contract, saas: saas, price_cents: 50000, billing_cycle: "monthly")

      get root_path
      expect(response.body).to include("コスト概要")
      expect(response.body).to include("月額コスト")
      expect(response.body).to include("年額コスト")
    end

    it "カテゴリ別コスト内訳を表示する" do
      saas1 = create(:saas, category: "一般IT")
      create(:saas_contract, saas: saas1, price_cents: 50000, billing_cycle: "monthly")
      saas2 = create(:saas, category: "バックオフィス")
      create(:saas_contract, saas: saas2, price_cents: 30000, billing_cycle: "monthly")

      get root_path
      expect(response.body).to include("一般IT")
      expect(response.body).to include("バックオフィス")
    end

    it "契約がなければコストセクションを表示しない" do
      get root_path
      expect(response.body).not_to include("コスト概要")
    end
  end
end
