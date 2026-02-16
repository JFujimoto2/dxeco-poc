require "rails_helper"

RSpec.describe Saas, type: :model do
  describe "バリデーション" do
    it "正しい属性で有効" do
      saas = build(:saas)
      expect(saas).to be_valid
    end

    it "name が必須" do
      saas = build(:saas, name: nil)
      expect(saas).not_to be_valid
    end
  end

  describe "enum" do
    it "active ステータス" do
      saas = build(:saas, status: "active")
      expect(saas).to be_active
    end

    it "cancelled ステータス" do
      saas = build(:saas, :cancelled)
      expect(saas).to be_cancelled
    end
  end

  describe "スコープ" do
    before do
      create(:saas, name: "Slack", category: "一般", status: "active")
      create(:saas, name: "いえらぶCLOUD", category: "不動産管理", status: "cancelled")
    end

    it "search_by_name で名前検索" do
      expect(Saas.search_by_name("Slack").count).to eq(1)
    end

    it "filter_by_category でカテゴリ絞り込み" do
      expect(Saas.filter_by_category("不動産管理").count).to eq(1)
    end

    it "filter_by_status でステータス絞り込み" do
      expect(Saas.filter_by_status("active").count).to eq(1)
    end
  end

  describe "セキュリティ属性 enum" do
    it "auth_method: sso" do
      saas = build(:saas, auth_method: "sso")
      expect(saas).to be_sso
    end

    it "auth_method: password" do
      saas = build(:saas, auth_method: "password")
      expect(saas).to be_password
    end

    it "auth_method: mfa" do
      saas = build(:saas, auth_method: "mfa")
      expect(saas).to be_mfa
    end

    it "data_location: domestic" do
      saas = build(:saas, data_location: "domestic")
      expect(saas).to be_domestic
    end

    it "data_location: overseas" do
      saas = build(:saas, data_location: "overseas")
      expect(saas).to be_overseas
    end

    it "data_location: unknown" do
      saas = build(:saas, data_location: "unknown")
      expect(saas).to be_unknown
    end
  end

  describe "セキュリティスコープ" do
    before do
      create(:saas, name: "SSO対応", auth_method: "sso", handles_personal_data: true, data_location: "domestic")
      create(:saas, name: "パスワード個人情報", auth_method: "password", handles_personal_data: true, data_location: "overseas")
      create(:saas, name: "MFA海外", auth_method: "mfa", handles_personal_data: false, data_location: "overseas")
      create(:saas, name: "未設定", auth_method: nil, handles_personal_data: false, data_location: nil)
    end

    it "filter_by_auth_method で認証方式絞り込み" do
      expect(Saas.filter_by_auth_method("sso").count).to eq(1)
      expect(Saas.filter_by_auth_method("password").count).to eq(1)
    end

    it "filter_by_auth_method が空なら全件返す" do
      expect(Saas.filter_by_auth_method(nil).count).to eq(4)
      expect(Saas.filter_by_auth_method("").count).to eq(4)
    end

    it "filter_by_data_location でデータ保存先絞り込み" do
      expect(Saas.filter_by_data_location("overseas").count).to eq(2)
      expect(Saas.filter_by_data_location("domestic").count).to eq(1)
    end

    it "filter_by_data_location が空なら全件返す" do
      expect(Saas.filter_by_data_location(nil).count).to eq(4)
    end

    it "personal_data_without_sso で個人情報+SSO未対応を返す" do
      result = Saas.personal_data_without_sso
      expect(result.map(&:name)).to contain_exactly("パスワード個人情報")
    end

    it "personal_data_overseas で個人情報+海外データ保存を返す" do
      result = Saas.personal_data_overseas
      expect(result.map(&:name)).to contain_exactly("パスワード個人情報")
    end
  end

  describe "部署フィルタースコープ" do
    it "filter_by_department で部署のユーザーが使うSaaSを返す" do
      user_sales = create(:user, department: "営業部")
      user_it = create(:user, department: "情報システム部")
      saas_a = create(:saas, name: "SaaS A")
      saas_b = create(:saas, name: "SaaS B")
      create(:saas_account, saas: saas_a, user: user_sales)
      create(:saas_account, saas: saas_b, user: user_it)

      result = Saas.filter_by_department("営業部")
      expect(result.map(&:name)).to contain_exactly("SaaS A")
    end

    it "filter_by_department が空なら全件返す" do
      create(:saas, name: "SaaS X")
      expect(Saas.filter_by_department(nil).count).to eq(1)
      expect(Saas.filter_by_department("").count).to eq(1)
    end
  end

  describe "アソシエーション" do
    it "saas_contract を持てる" do
      saas = create(:saas, :with_contract)
      expect(saas.saas_contract).to be_present
    end
  end
end
