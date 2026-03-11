require "rails_helper"

RSpec.describe GraphApiDelivery do
  let(:delivery) { described_class.new({}) }

  describe "#deliver!" do
    let(:mail) do
      Mail.new do
        from    "saas-mgmt@example.com"
        to      "user@example.com"
        subject "テスト件名"
        body    "テスト本文"
      end
    end

    before do
      allow(EntraClient).to receive(:fetch_app_token).and_return("test-token")
    end

    it "Graph API sendMail エンドポイントにPOSTする" do
      stub = stub_request(:post, "https://graph.microsoft.com/v1.0/users/saas-mgmt@example.com/sendMail")
        .with(headers: { "Authorization" => "Bearer test-token", "Content-Type" => "application/json" })
        .to_return(status: 202, body: "")

      delivery.deliver!(mail)
      expect(stub).to have_been_requested
    end

    it "リクエストボディに subject, toRecipients, body が含まれる" do
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      delivery.deliver!(mail)

      expect(WebMock).to have_requested(:post, /sendMail/).with { |req|
        body = JSON.parse(req.body)
        message = body["message"]
        message["subject"] == "テスト件名" &&
          message["toRecipients"][0]["emailAddress"]["address"] == "user@example.com" &&
          message["body"]["content"] == "テスト本文"
      }
    end

    it "複数のto宛先に対応する" do
      mail.to = [ "user1@example.com", "user2@example.com" ]
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      delivery.deliver!(mail)

      expect(WebMock).to have_requested(:post, /sendMail/).with { |req|
        body = JSON.parse(req.body)
        body["message"]["toRecipients"].size == 2
      }
    end

    it "CC宛先がある場合は ccRecipients に含まれる" do
      mail.cc = "manager@example.com"
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      delivery.deliver!(mail)

      expect(WebMock).to have_requested(:post, /sendMail/).with { |req|
        body = JSON.parse(req.body)
        body["message"]["ccRecipients"][0]["emailAddress"]["address"] == "manager@example.com"
      }
    end

    it "HTML本文がある場合は contentType が HTML になる" do
      html_mail = Mail.new do
        from    "saas-mgmt@example.com"
        to      "user@example.com"
        subject "テスト"
        content_type "text/html"
        body "<p>テスト</p>"
      end
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      delivery.deliver!(html_mail)

      expect(WebMock).to have_requested(:post, /sendMail/).with { |req|
        body = JSON.parse(req.body)
        body["message"]["body"]["contentType"] == "HTML"
      }
    end

    it "multipart メールの場合は HTML パートを優先する" do
      multipart_mail = Mail.new do
        from    "saas-mgmt@example.com"
        to      "user@example.com"
        subject "テスト"
        text_part { body "テキスト版" }
        html_part { content_type "text/html"; body "<p>HTML版</p>" }
      end
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      delivery.deliver!(multipart_mail)

      expect(WebMock).to have_requested(:post, /sendMail/).with { |req|
        body = JSON.parse(req.body)
        body["message"]["body"]["contentType"] == "HTML" &&
          body["message"]["body"]["content"].include?("HTML版")
      }
    end

    it "APIエラー時に例外を発生させる" do
      stub_request(:post, /sendMail/)
        .to_return(status: 403, body: { error: { message: "Forbidden" } }.to_json)

      expect { delivery.deliver!(mail) }.to raise_error(GraphApiDelivery::DeliveryError, /403/)
    end

    it "EntraClient.fetch_app_token でトークンを取得する" do
      stub_request(:post, /sendMail/).to_return(status: 202, body: "")

      expect(EntraClient).to receive(:fetch_app_token).and_return("test-token")
      delivery.deliver!(mail)
    end
  end
end
