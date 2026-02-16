require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  describe "ログインのRate Limiting" do
    it "dev_loginに短時間で6回アクセスすると429を返す" do
      user = create(:user)
      5.times do
        post dev_login_path, params: { email: user.email }
      end
      post dev_login_path, params: { email: user.email }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "一般リクエストのRate Limiting" do
    it "ヘルスチェックはRate Limitingの対象外" do
      # /up is excluded from throttling
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end
end
