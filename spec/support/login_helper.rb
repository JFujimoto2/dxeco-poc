module LoginHelper
  def login_as(user)
    post dev_login_path, params: { email: user.email, display_name: user.display_name }
  end
end

RSpec.configure do |config|
  config.include LoginHelper, type: :request
end
