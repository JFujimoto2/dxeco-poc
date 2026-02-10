FactoryBot.define do
  factory :saas_account do
    saas
    user
    account_email { user.email }
    role { "member" }
    status { "active" }
  end
end
