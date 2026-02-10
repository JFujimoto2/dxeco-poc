FactoryBot.define do
  factory :survey_response do
    association :survey
    association :user
    association :saas_account
    response { nil }
    responded_at { nil }
  end
end
