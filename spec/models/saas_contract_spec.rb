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

  describe "スコープ" do
    describe ".expiring_soon" do
      it "30日以内に期限が来る契約を返す" do
        expiring = create(:saas_contract, expires_on: 15.days.from_now.to_date)
        not_expiring = create(:saas_contract, expires_on: 60.days.from_now.to_date)
        expired = create(:saas_contract, expires_on: 5.days.ago.to_date)

        result = SaasContract.expiring_soon
        expect(result).to include(expiring)
        expect(result).not_to include(not_expiring)
        expect(result).not_to include(expired)
      end

      it "日数を指定できる" do
        within_7 = create(:saas_contract, expires_on: 5.days.from_now.to_date)
        within_30 = create(:saas_contract, expires_on: 20.days.from_now.to_date)

        result = SaasContract.expiring_soon(7)
        expect(result).to include(within_7)
        expect(result).not_to include(within_30)
      end

      it "expires_on が nil の契約は含まれない" do
        create(:saas_contract, expires_on: nil)
        expect(SaasContract.expiring_soon).to be_empty
      end
    end

    describe ".expired" do
      it "期限切れの契約のみ返す" do
        expired = create(:saas_contract, expires_on: 5.days.ago.to_date)
        not_expired = create(:saas_contract, expires_on: 15.days.from_now.to_date)

        result = SaasContract.expired
        expect(result).to include(expired)
        expect(result).not_to include(not_expired)
      end

      it "expires_on が nil の契約は含まれない" do
        create(:saas_contract, expires_on: nil)
        expect(SaasContract.expired).to be_empty
      end
    end
  end

  describe "コスト計算" do
    describe "#monthly_cost_cents" do
      it "月額契約はそのまま返す" do
        contract = build(:saas_contract, price_cents: 10000, billing_cycle: "monthly")
        expect(contract.monthly_cost_cents).to eq(10000)
      end

      it "年額契約は12で割る" do
        contract = build(:saas_contract, price_cents: 120000, billing_cycle: "yearly")
        expect(contract.monthly_cost_cents).to eq(10000)
      end

      it "price_centsがnilなら0を返す" do
        contract = build(:saas_contract, price_cents: nil, billing_cycle: "monthly")
        expect(contract.monthly_cost_cents).to eq(0)
      end
    end

    describe "#annual_cost_cents" do
      it "月額契約は12倍する" do
        contract = build(:saas_contract, price_cents: 10000, billing_cycle: "monthly")
        expect(contract.annual_cost_cents).to eq(120000)
      end

      it "年額契約はそのまま返す" do
        contract = build(:saas_contract, price_cents: 120000, billing_cycle: "yearly")
        expect(contract.annual_cost_cents).to eq(120000)
      end

      it "price_centsがnilなら0を返す" do
        contract = build(:saas_contract, price_cents: nil, billing_cycle: "yearly")
        expect(contract.annual_cost_cents).to eq(0)
      end
    end
  end
end
