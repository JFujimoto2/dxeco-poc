require "rails_helper"

RSpec.describe SaasContract, type: :model do
  describe "バリデーション" do
    it "正しい属性で有効" do
      contract = build(:saas_contract)
      expect(contract).to be_valid
    end

    it "saas_id の一意性" do
      saas = create(:saas)
      create(:saas_contract, saas: saas)
      contract = build(:saas_contract, saas: saas)
      expect(contract).not_to be_valid
    end
  end
end
