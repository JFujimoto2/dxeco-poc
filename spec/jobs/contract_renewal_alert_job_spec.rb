require "rails_helper"

RSpec.describe ContractRenewalAlertJob, type: :job do
  it "30日以内の契約があればTeams通知を送信する" do
    saas = create(:saas, name: "Slack")
    create(:saas_contract, saas: saas, expires_on: 10.days.from_now.to_date, plan_name: "Business")

    expect(TeamsNotifier).to receive(:notify).with(hash_including(title: /契約更新/))

    expect {
      ContractRenewalAlertJob.perform_now
    }.to change(BatchExecutionLog, :count).by(1)

    log = BatchExecutionLog.last
    expect(log).to be_success
    expect(log.created_count).to eq(1)
  end

  it "該当する契約がなければ通知しない" do
    saas = create(:saas, name: "Zoom")
    create(:saas_contract, saas: saas, expires_on: 60.days.from_now.to_date)

    expect(TeamsNotifier).not_to receive(:notify)

    ContractRenewalAlertJob.perform_now
    log = BatchExecutionLog.last
    expect(log).to be_success
    expect(log.created_count).to eq(0)
  end

  it "BatchExecutionLogが記録される" do
    ContractRenewalAlertJob.perform_now
    log = BatchExecutionLog.last
    expect(log.job_name).to eq("ContractRenewalAlertJob")
    expect(log).to be_success
  end
end
