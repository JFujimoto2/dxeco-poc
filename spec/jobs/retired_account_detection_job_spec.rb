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

  it "残存アカウントがある場合はTeams通知を送信する" do
    retired_user = create(:user, account_enabled: false, display_name: "退職者太郎")
    saas = create(:saas, name: "GitHub")
    create(:saas_account, user: retired_user, saas: saas, status: "active")

    expect(TeamsNotifier).to receive(:notify).with(hash_including(title: /退職者アカウント検出/))
    RetiredAccountDetectionJob.perform_now
  end

  it "残存アカウントがない場合はTeams通知を送信しない" do
    create(:user, account_enabled: false) # 退職者だがアカウントなし

    expect(TeamsNotifier).not_to receive(:notify)
    RetiredAccountDetectionJob.perform_now
  end
end
