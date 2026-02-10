require "rails_helper"

RSpec.describe SaasAccount, type: :model do
  describe "バリデーション" do
    it "正しい属性で有効" do
      account = build(:saas_account)
      expect(account).to be_valid
    end

    it "saas + user の組み合わせが一意" do
      saas = create(:saas)
      user = create(:user)
      create(:saas_account, saas: saas, user: user)
      account = build(:saas_account, saas: saas, user: user)
      expect(account).not_to be_valid
    end
  end

  describe "enum" do
    it "active ステータス" do
      account = build(:saas_account, status: "active")
      expect(account).to be_active
    end

    it "suspended ステータス" do
      account = build(:saas_account, status: "suspended")
      expect(account).to be_suspended
    end
  end
end
