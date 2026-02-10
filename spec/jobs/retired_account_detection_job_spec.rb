require "rails_helper"

RSpec.describe RetiredAccountDetectionJob, type: :job do
  it "退職者の残存アカウントを検出する" do
    retired_user = create(:user, account_enabled: false)
    saas = create(:saas, name: "Slack")
    create(:saas_account, user: retired_user, saas: saas, status: "active")

    expect {
      RetiredAccountDetectionJob.perform_now
    }.to change(BatchExecutionLog, :count).by(1)

    log = BatchExecutionLog.last
    expect(log).to be_success
    expect(log.processed_count).to eq(1)
    expect(log.created_count).to eq(1) # 1 user with remaining accounts
  end

  it "退職者がいない場合も正常に完了" do
    RetiredAccountDetectionJob.perform_now
    log = BatchExecutionLog.last
    expect(log).to be_success
    expect(log.created_count).to eq(0)
  end
end
