FactoryBot.define do
  factory :task_item do
    association :task
    action_type { "account_delete" }
    description { "テストアカウント削除" }
    status { "pending" }
  end
end
