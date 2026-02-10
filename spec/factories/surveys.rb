FactoryBot.define do
  factory :survey do
    sequence(:title) { |n| "サーベイ #{n}" }
    survey_type { "account_review" }
    association :created_by, factory: :user
    status { "draft" }
    deadline { 2.weeks.from_now }
  end
end
