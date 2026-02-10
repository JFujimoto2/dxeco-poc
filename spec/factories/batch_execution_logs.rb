FactoryBot.define do
  factory :batch_execution_log do
    job_name { "EntraUserSyncJob" }
    status { "running" }
    started_at { Time.current }
  end
end
