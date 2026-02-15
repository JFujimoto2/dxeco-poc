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

  it "7日以内の契約と30日以内の契約を区別して通知する" do
    saas1 = create(:saas, name: "Slack")
    saas2 = create(:saas, name: "Zoom")
    create(:saas_contract, saas: saas1, expires_on: 3.days.from_now.to_date, plan_name: "Pro")
    create(:saas_contract, saas: saas2, expires_on: 20.days.from_now.to_date, plan_name: "Business")

    expect(TeamsNotifier).to receive(:notify) do |args|
      expect(args[:body]).to include("7日以内")
      expect(args[:body]).to include("Slack")
      expect(args[:body]).to include("30日以内")
      expect(args[:body]).to include("Zoom")
    end

    ContractRenewalAlertJob.perform_now
  end

  it "エラー発生時にBatchExecutionLogにfailureを記録する" do
    allow(SaasContract).to receive(:expiring_soon).and_raise(StandardError, "テストエラー")

    expect {
      ContractRenewalAlertJob.perform_now
    }.to raise_error(StandardError)

    log = BatchExecutionLog.last
    expect(log.status).to eq("failure")
    expect(log.error_messages).to include("テストエラー")
  end
end
