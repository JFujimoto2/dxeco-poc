class GraphApiDelivery
  class DeliveryError < StandardError; end

  GRAPH_SEND_MAIL_URL = "https://graph.microsoft.com/v1.0/users/%s/sendMail"

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    sender = mail.from.first
    token = EntraClient.fetch_app_token
    url = format(GRAPH_SEND_MAIL_URL, sender)

    response = Faraday.post(url) do |req|
      req.headers["Authorization"] = "Bearer #{token}"
      req.headers["Content-Type"] = "application/json"
      req.body = build_payload(mail).to_json
    end

    unless response.status == 202
      raise DeliveryError, "Graph API sendMail failed (#{response.status}): #{response.body}"
    end
  end

  private

  def build_payload(mail)
    {
      message: {
        subject: mail.subject,
        body: build_body(mail),
        toRecipients: build_recipients(mail.to),
        ccRecipients: build_recipients(mail.cc)
      }.compact,
      saveToSentItems: false
    }
  end

  def build_body(mail)
    if mail.html_part
      { contentType: "HTML", content: mail.html_part.body.to_s }
    elsif mail.content_type&.include?("text/html")
      { contentType: "HTML", content: mail.body.to_s }
    else
      { contentType: "Text", content: (mail.text_part || mail).body.to_s }
    end
  end

  def build_recipients(addresses)
    return nil if addresses.blank?

    Array(addresses).map do |addr|
      { emailAddress: { address: addr } }
    end
  end
end
