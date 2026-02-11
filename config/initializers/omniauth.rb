Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["ENTRA_CLIENT_ID"].present?
    provider :openid_connect,
      name: :entra_id,
      scope: [ :openid, :profile, :email ],
      discovery: true,
      issuer: "https://login.microsoftonline.com/#{ENV['ENTRA_TENANT_ID']}/v2.0",
      client_options: {
        identifier: ENV["ENTRA_CLIENT_ID"],
        secret: ENV["ENTRA_CLIENT_SECRET"],
        redirect_uri: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/auth/entra_id/callback",
        host: "login.microsoftonline.com",
        scheme: "https",
        authorization_endpoint: "/#{ENV['ENTRA_TENANT_ID']}/oauth2/v2.0/authorize",
        token_endpoint: "/#{ENV['ENTRA_TENANT_ID']}/oauth2/v2.0/token"
      }
  end
end

OmniAuth.config.allowed_request_methods = [ :post ]
