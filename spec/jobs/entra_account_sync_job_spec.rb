require "rails_helper"

RSpec.describe EntraAccountSyncJob, type: :job do
  let!(:user1) { create(:user, entra_id_sub: "user-001", email: "taro@example.com") }
  let!(:user2) { create(:user, entra_id_sub: "user-002", email: "hanako@example.com") }
  let!(:slack) { create(:saas, name: "Slack") }
  let!(:zoom) { create(:saas, name: "Zoom") }

  let(:service_principals) do
    [
      { "id" => "sp-slack", "displayName" => "Slack", "appId" => "app-slack" },
      { "id" => "sp-zoom", "displayName" => "Zoom", "appId" => "app-zoom" },
      { "id" => "sp-unknown", "displayName" => "UnknownApp", "appId" => "app-unknown" }
    ]
  end

  let(:slack_assignments) do
    [
      { "principalId" => "user-001", "principalDisplayName" => "テスト太郎", "principalType" => "User" },
      { "principalId" => "user-002", "principalDisplayName" => "テスト花子", "principalType" => "User" }
    ]
  end

  let(:zoom_assignments) do
    [
      { "principalId" => "user-001", "principalDisplayName" => "テスト太郎", "principalType" => "User" }
    ]
  end

  before do
    stub_request(:post, /login\.microsoftonline\.com/).to_return(
      status: 200, body: { access_token: "token" }.to_json
    )
    allow(EntraClient).to receive(:fetch_service_principals).and_return(service_principals)
    allow(EntraClient).to receive(:fetch_app_role_assignments).with("token", "sp-slack").and_return(slack_assignments)
    allow(EntraClient).to receive(:fetch_app_role_assignments).with("token", "sp-zoom").and_return(zoom_assignments)
    allow(EntraClient).to receive(:fetch_app_role_assignments).with("token", "sp-unknown").and_return([])
  end

  it "エンタープライズアプリからSaaSアカウントを同期する" do
    expect { EntraAccountSyncJob.perform_now }.to change(SaasAccount, :count).by(3)

    expect(SaasAccount.find_by(saas: slack, user: user1)).to be_present
    expect(SaasAccount.find_by(saas: slack, user: user2)).to be_present
    expect(SaasAccount.find_by(saas: zoom, user: user1)).to be_present
  end

  it "名前マッチングでentra_app_idを設定する" do
    EntraAccountSyncJob.perform_now

    expect(slack.reload.entra_app_id).to eq("sp-slack")
    expect(zoom.reload.entra_app_id).to eq("sp-zoom")
  end

  it "entra_app_idが設定済みならIDでマッチングする" do
    slack.update!(entra_app_id: "sp-slack")

    EntraAccountSyncJob.perform_now

    expect(SaasAccount.find_by(saas: slack, user: user1)).to be_present
  end

  it "割り当て解除されたアカウントをsuspendedにする" do
    existing_account = create(:saas_account, saas: slack, user: user2, status: "active")
    # user2はslack_assignmentsに含まれているので維持される

    # user2をslack割り当てから除外
    allow(EntraClient).to receive(:fetch_app_role_assignments).with("token", "sp-slack").and_return(
      [ { "principalId" => "user-001", "principalDisplayName" => "テスト太郎", "principalType" => "User" } ]
    )

    EntraAccountSyncJob.perform_now
    expect(existing_account.reload.status).to eq("suspended")
  end

  it "マッチするSaaSがないアプリはスキップする" do
    # sp-unknownはSaaSレコードがないのでスキップされる
    expect { EntraAccountSyncJob.perform_now }.not_to raise_error
  end

  it "BatchExecutionLogを作成する" do
    expect { EntraAccountSyncJob.perform_now }.to change(BatchExecutionLog, :count).by(1)

    log = BatchExecutionLog.last
    expect(log.job_name).to eq("EntraAccountSyncJob")
    expect(log.status).to eq("success")
    expect(log.created_count).to be >= 3
  end

  it "Teams通知を送信する" do
    allow(TeamsNotifier).to receive(:notify)
    stub_const("TeamsNotifier::WEBHOOK_URL", "https://teams.example.com/webhook")

    EntraAccountSyncJob.perform_now

    expect(TeamsNotifier).to have_received(:notify).with(hash_including(title: "SaaSアカウント同期完了"))
  end
end
