class TeamsNotifier
  WEBHOOK_URL = ENV["TEAMS_WEBHOOK_URL"]

  def self.notify(title:, body:, level: :info)
    return unless WEBHOOK_URL.present?

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
    Faraday.post(WEBHOOK_URL, payload.to_json, "Content-Type" => "application/json")
  end
end
