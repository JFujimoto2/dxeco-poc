FactoryBot.define do
  factory :saas_contract do
    saas
    plan_name { "Standard" }
    price_cents { 10000 }
    billing_cycle { "monthly" }
  end
end
