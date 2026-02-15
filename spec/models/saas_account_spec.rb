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

    it "role enum が正しく定義されている" do
      account = build(:saas_account, role: "admin")
      expect(account).to be_admin
    end

    it "不正なroleは例外を発生させる" do
      expect { build(:saas_account, role: "superadmin") }.to raise_error(ArgumentError)
    end
  end
end
