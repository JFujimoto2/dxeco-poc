FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "タスク #{n}" }
    task_type { "offboarding" }
    association :target_user, factory: :user
    association :created_by, factory: :user
    status { "open" }
    due_date { 2.weeks.from_now.to_date }
  end
end
