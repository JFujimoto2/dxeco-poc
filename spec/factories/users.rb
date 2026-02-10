FactoryBot.define do
  factory :user do
    sequence(:entra_id_sub) { |n| "entra-#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "テストユーザー" }
    role { "viewer" }

    trait :admin do
      role { "admin" }
    end

    trait :manager do
      role { "manager" }
    end
  end
end
