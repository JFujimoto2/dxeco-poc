require "rails_helper"

RSpec.describe TeamsNotifier do
  describe ".notify" do
    it "WEBHOOK_URLが未設定の場合は何もしない" do
      stub_const("TeamsNotifier::WEBHOOK_URL", nil)
      expect(Faraday).not_to receive(:post)
      TeamsNotifier.notify(title: "テスト", body: "本文")
    end

    it "WEBHOOK_URLが設定されている場合はPOSTする" do
      stub_const("TeamsNotifier::WEBHOOK_URL", "https://example.com/webhook")
      stub_request(:post, "https://example.com/webhook").to_return(status: 200)
      TeamsNotifier.notify(title: "テスト通知", body: "テスト本文")
      expect(WebMock).to have_requested(:post, "https://example.com/webhook")
    end
  end
end
