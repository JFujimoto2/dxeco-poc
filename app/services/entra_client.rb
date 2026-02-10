class EntraClient
  BASE_URL = "https://graph.microsoft.com/v1.0"

  def self.fetch_app_token
    tenant_id = ENV["ENTRA_TENANT_ID"]
    response = Faraday.post(
      "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token",
      client_id: ENV["ENTRA_CLIENT_ID"],
      client_secret: ENV["ENTRA_CLIENT_SECRET"],
      scope: "https://graph.microsoft.com/.default",
      grant_type: "client_credentials"
    )
    JSON.parse(response.body)["access_token"]
  end

  def self.fetch_all_users(token)
    url = "#{BASE_URL}/users?$select=id,displayName,mail,userPrincipalName,jobTitle,department,employeeId,accountEnabled&$top=999"
    users = []
    loop do
      response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{token}"
      end
      data = JSON.parse(response.body)
      users.concat(data["value"] || [])
      url = data["@odata.nextLink"]
      break unless url
    end
    users
  end
end
