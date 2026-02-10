FactoryBot.define do
  factory :task_preset_item do
    association :task_preset
    action_type { "account_delete" }
    description { "テストタスク項目" }
    position { 0 }
  end
end
