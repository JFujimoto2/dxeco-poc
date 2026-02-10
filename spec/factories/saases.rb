FactoryBot.define do
  factory :saas do
    sequence(:name) { |n| "SaaS #{n}" }
    category { "一般" }
    status { "active" }

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_contract do
      after(:create) do |saas|
        create(:saas_contract, saas: saas)
      end
    end
  end
end
