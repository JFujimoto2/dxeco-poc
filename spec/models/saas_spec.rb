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

  describe "アソシエーション" do
    it "saas_contract を持てる" do
      saas = create(:saas, :with_contract)
      expect(saas.saas_contract).to be_present
    end
  end
end
