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
      stub_request(:get, "https://graph.microsoft.com/v1.0/users?$select=id,displayName,mail,userPrincipalName,jobTitle,department,employeeId,accountEnabled&$top=999")
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
end
