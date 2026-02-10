FactoryBot.define do
  factory :approval_request do
    request_type { "new_saas" }
    association :requester, factory: :user
    saas_name { "TestSaaS" }
    reason { "テスト申請理由" }
    status { "pending" }
  end
end
