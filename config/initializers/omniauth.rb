Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["ENTRA_CLIENT_ID"].present?
    provider :openid_connect,
      name: :entra_id,
      scope: [ :openid, :profile, :email, "User.Read" ],
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
  elsif Rails.env.test?
    provider :openid_connect,
      name: :entra_id,
      scope: [ :openid ],
      client_options: {
        identifier: "test",
        secret: "test",
        redirect_uri: "http://localhost:3000/auth/entra_id/callback"
      }
  end
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.logger = Rails.logger

OmniAuth.config.on_failure = Proc.new do |env|
  error = env["omniauth.error"]
  strategy = env["omniauth.error.strategy"]
  type = env["omniauth.error.type"]
  Rails.logger.error "[OmniAuth Failure] type=#{type}, error=#{error&.class}: #{error&.message}"
  Rails.logger.error "[OmniAuth Failure] strategy=#{strategy&.name}" if strategy
  Rails.logger.error "[OmniAuth Failure] backtrace: #{error&.backtrace&.first(5)&.join("\n")}" if error
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
