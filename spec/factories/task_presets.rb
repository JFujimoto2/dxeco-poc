FactoryBot.define do
  factory :task_preset do
    sequence(:name) { |n| "プリセット #{n}" }
    task_type { "offboarding" }
    description { "テスト用プリセット" }
  end
end
