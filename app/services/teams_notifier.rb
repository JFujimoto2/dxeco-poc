class TeamsNotifier
  WEBHOOK_URL = ENV["TEAMS_WEBHOOK_URL"]
  SURVEY_WEBHOOK_URL = ENV["TEAMS_WEBHOOK_SURVEY_URL"]

  def self.notify(title:, body:, level: :info, webhook_url: nil)
    url = webhook_url.presence || WEBHOOK_URL
    return unless url.present?

    payload = {
      type: "message",
      attachments: [ {
        contentType: "application/vnd.microsoft.card.adaptive",
        content: {
          "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
          type: "AdaptiveCard",
          version: "1.4",
          body: [
            { type: "TextBlock", text: title, weight: "Bolder", size: "Medium" },
            { type: "TextBlock", text: body, wrap: true }
          ]
        }
      } ]
    }
    Faraday.post(url, payload.to_json, "Content-Type" => "application/json")
  end
end
