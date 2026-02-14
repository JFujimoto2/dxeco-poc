require "rails_helper"

RSpec.describe EntraUserSyncJob, type: :job do
  let(:entra_users) do
    [
      { "id" => "oid-001", "displayName" => "テスト太郎", "mail" => "taro@example.com",
        "department" => "営業部", "jobTitle" => "課長", "employeeId" => "EMP001", "accountEnabled" => true }
    ]
  end

  before do
    stub_request(:post, /login\.microsoftonline\.com/).to_return(status: 200, body: { access_token: "token" }.to_json)
    stub_request(:get, /graph\.microsoft\.com/).to_return(status: 200, body: { value: entra_users }.to_json)
  end

  it "新規ユーザーを作成する" do
    expect { EntraUserSyncJob.perform_now }.to change(User, :count).by(1)
    user = User.find_by(entra_id_sub: "oid-001")
    expect(user.display_name).to eq("テスト太郎")
    expect(user.department).to eq("営業部")
  end

  it "既存ユーザーをentra_id_subで更新する" do
    create(:user, entra_id_sub: "oid-001", email: "taro@example.com", display_name: "旧名前")

    expect { EntraUserSyncJob.perform_now }.not_to change(User, :count)
    expect(User.find_by(entra_id_sub: "oid-001").display_name).to eq("テスト太郎")
  end

  it "SSO登録済みユーザーをemailでマッチして重複を防ぐ" do
    # SSO ログインで oid ではなく sub で登録されたケースのフォールバック
    create(:user, entra_id_sub: "old-sub-value", email: "taro@example.com", display_name: "旧名前")

    expect { EntraUserSyncJob.perform_now }.not_to change(User, :count)
    user = User.find_by(email: "taro@example.com")
    expect(user.entra_id_sub).to eq("oid-001")
    expect(user.display_name).to eq("テスト太郎")
  end

  it "lastPasswordChangeDateTimeを同期する" do
    entra_users_with_pwd = [
      { "id" => "oid-001", "displayName" => "テスト太郎", "mail" => "taro@example.com",
        "department" => "営業部", "jobTitle" => "課長", "employeeId" => "EMP001",
        "accountEnabled" => true, "lastPasswordChangeDateTime" => "2026-01-15T10:30:00Z" }
    ]
    stub_request(:get, /graph\.microsoft\.com/).to_return(
      status: 200, body: { value: entra_users_with_pwd }.to_json
    )

    EntraUserSyncJob.perform_now
    user = User.find_by(entra_id_sub: "oid-001")
    expect(user.last_password_change_at).to be_present
    expect(user.last_password_change_at).to eq(Time.parse("2026-01-15T10:30:00Z"))
  end
end
