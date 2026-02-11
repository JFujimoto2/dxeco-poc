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

    it "webhook_url引数で送信先を上書きできる" do
      stub_const("TeamsNotifier::WEBHOOK_URL", "https://example.com/default")
      custom_url = "https://example.com/survey-channel"
      stub_request(:post, custom_url).to_return(status: 200)
      TeamsNotifier.notify(title: "サーベイ通知", body: "本文", webhook_url: custom_url)
      expect(WebMock).to have_requested(:post, custom_url)
      expect(WebMock).not_to have_requested(:post, "https://example.com/default")
    end

    it "webhook_url引数がnilの場合はデフォルトURLを使う" do
      stub_const("TeamsNotifier::WEBHOOK_URL", "https://example.com/default")
      stub_request(:post, "https://example.com/default").to_return(status: 200)
      TeamsNotifier.notify(title: "通知", body: "本文", webhook_url: nil)
      expect(WebMock).to have_requested(:post, "https://example.com/default")
    end

    it "link指定時にAction.OpenUrlボタンを含める" do
      stub_const("TeamsNotifier::WEBHOOK_URL", "https://example.com/webhook")
      stub_request(:post, "https://example.com/webhook").to_return(status: 200)
      TeamsNotifier.notify(title: "テスト", body: "本文", link: "http://localhost:3000/approval_requests/1")

      expect(WebMock).to have_requested(:post, "https://example.com/webhook").with { |req|
        payload = JSON.parse(req.body)
        actions = payload.dig("attachments", 0, "content", "actions")
        actions.present? &&
          actions[0]["type"] == "Action.OpenUrl" &&
          actions[0]["url"] == "http://localhost:3000/approval_requests/1"
      }
    end

    it "link未指定時はactionsを含めない" do
      stub_const("TeamsNotifier::WEBHOOK_URL", "https://example.com/webhook")
      stub_request(:post, "https://example.com/webhook").to_return(status: 200)
      TeamsNotifier.notify(title: "テスト", body: "本文")

      expect(WebMock).to have_requested(:post, "https://example.com/webhook").with { |req|
        payload = JSON.parse(req.body)
        actions = payload.dig("attachments", 0, "content", "actions")
        actions.nil?
      }
    end
  end
end
