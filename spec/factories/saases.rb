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

    trait :handles_personal_data do
      handles_personal_data { true }
    end

    trait :sso_auth do
      auth_method { "sso" }
    end

    trait :password_auth do
      auth_method { "password" }
    end

    trait :domestic_data do
      data_location { "domestic" }
    end

    trait :overseas_data do
      data_location { "overseas" }
    end

    trait :risky do
      handles_personal_data { true }
      auth_method { "password" }
      data_location { "overseas" }
    end
  end
end
