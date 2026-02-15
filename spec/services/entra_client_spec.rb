require "rails_helper"

RSpec.describe EntraClient do
  describe ".fetch_app_token" do
    it "アクセストークンを取得する" do
      stub_request(:post, /login\.microsoftonline\.com/)
        .to_return(status: 200, body: { access_token: "test-token" }.to_json)

      token = EntraClient.fetch_app_token
      expect(token).to eq("test-token")
    end
  end

  describe ".fetch_all_users" do
    it "ユーザー一覧を取得する" do
      stub_request(:get, /graph\.microsoft\.com/)
        .to_return(status: 200, body: {
          value: [
            { "id" => "user-1", "displayName" => "テスト太郎", "mail" => "test@example.com", "accountEnabled" => true }
          ]
        }.to_json)

      users = EntraClient.fetch_all_users("test-token")
      expect(users.size).to eq(1)
      expect(users.first["displayName"]).to eq("テスト太郎")
    end

    it "ページネーションに対応する" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/users?$select=id,displayName,mail,userPrincipalName,jobTitle,department,employeeId,accountEnabled,lastPasswordChangeDateTime&$top=999")
        .to_return(status: 200, body: {
          value: [ { "id" => "user-1" } ],
          "@odata.nextLink" => "https://graph.microsoft.com/v1.0/users?$skiptoken=abc"
        }.to_json)
      stub_request(:get, "https://graph.microsoft.com/v1.0/users?$skiptoken=abc")
        .to_return(status: 200, body: {
          value: [ { "id" => "user-2" } ]
        }.to_json)

      users = EntraClient.fetch_all_users("test-token")
      expect(users.size).to eq(2)
    end
  end

  describe ".fetch_my_profile" do
    it "ログインユーザーのプロフィールを取得する" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me?$select=department,jobTitle,employeeId")
        .to_return(status: 200, body: {
          "department" => "情報システム部",
          "jobTitle" => "主任",
          "employeeId" => "EMP001"
        }.to_json)

      profile = EntraClient.fetch_my_profile("user-token")
      expect(profile["department"]).to eq("情報システム部")
      expect(profile["jobTitle"]).to eq("主任")
      expect(profile["employeeId"]).to eq("EMP001")
    end

    it "API失敗時はnilを返す" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me?$select=department,jobTitle,employeeId")
        .to_return(status: 401, body: { error: "Unauthorized" }.to_json)

      profile = EntraClient.fetch_my_profile("invalid-token")
      expect(profile).to be_nil
    end
  end

  describe ".fetch_service_principals" do
    it "SSO連携済みエンタープライズアプリ一覧を取得する" do
      stub_request(:get, /graph\.microsoft\.com\/v1\.0\/servicePrincipals/)
        .to_return(status: 200, body: {
          value: [
            { "id" => "sp-1", "displayName" => "Slack", "appId" => "app-1" },
            { "id" => "sp-2", "displayName" => "Zoom", "appId" => "app-2" }
          ]
        }.to_json)

      apps = EntraClient.fetch_service_principals("test-token")
      expect(apps.size).to eq(2)
      expect(apps.first["displayName"]).to eq("Slack")
    end

    it "ページネーションに対応する" do
      stub_request(:get, /servicePrincipals\?/)
        .to_return(status: 200, body: {
          value: [ { "id" => "sp-1" } ],
          "@odata.nextLink" => "https://graph.microsoft.com/v1.0/servicePrincipals?$skiptoken=abc"
        }.to_json)
      stub_request(:get, "https://graph.microsoft.com/v1.0/servicePrincipals?$skiptoken=abc")
        .to_return(status: 200, body: {
          value: [ { "id" => "sp-2" } ]
        }.to_json)

      apps = EntraClient.fetch_service_principals("test-token")
      expect(apps.size).to eq(2)
    end
  end

  describe ".fetch_app_role_assignments" do
    it "指定アプリのユーザー割り当てを取得する" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/servicePrincipals/sp-1/appRoleAssignedTo")
        .to_return(status: 200, body: {
          value: [
            { "principalId" => "user-1", "principalDisplayName" => "テスト太郎", "principalType" => "User" },
            { "principalId" => "group-1", "principalDisplayName" => "営業部", "principalType" => "Group" }
          ]
        }.to_json)

      assignments = EntraClient.fetch_app_role_assignments("test-token", "sp-1")
      expect(assignments.size).to eq(1)
      expect(assignments.first["principalId"]).to eq("user-1")
    end
  end
end
