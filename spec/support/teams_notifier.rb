RSpec.configure do |config|
  config.before do
    stub_const("TeamsNotifier::WEBHOOK_URL", nil)
    stub_const("TeamsNotifier::SURVEY_WEBHOOK_URL", nil)
  end
end
