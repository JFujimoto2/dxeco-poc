FactoryBot.define do
  factory :audit_log do
    user
    action { "create" }
    resource_type { "Saas" }
    sequence(:resource_id) { |n| n }
    changes_data { {} }
    ip_address { "127.0.0.1" }
  end
end
