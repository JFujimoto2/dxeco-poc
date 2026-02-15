class TeamsNotifier
  WEBHOOK_URL = ENV["TEAMS_WEBHOOK_URL"]
  SURVEY_WEBHOOK_URL = ENV["TEAMS_WEBHOOK_SURVEY_URL"]
  ERROR_WEBHOOK_URL = ENV["TEAMS_WEBHOOK_ERROR_URL"]

  def self.notify(title:, body:, level: :info, webhook_url: nil, link: nil)
    url = webhook_url.presence || WEBHOOK_URL
    return unless url.present?

    card_content = {
      "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
      type: "AdaptiveCard",
      version: "1.4",
      body: [
        { type: "TextBlock", text: title, weight: "Bolder", size: "Medium" },
        { type: "TextBlock", text: body, wrap: true }
      ]
    }

    if link.present?
      card_content[:actions] = [
        { type: "Action.OpenUrl", title: "詳細を見る", url: link }
      ]
    end

    payload = {
      type: "message",
      attachments: [ {
        contentType: "application/vnd.microsoft.card.adaptive",
        content: card_content
      } ]
    }
    Faraday.post(url, payload.to_json, "Content-Type" => "application/json")
  end

  def self.notify_error(error:, context: {})
    return unless ERROR_WEBHOOK_URL.present?

    title = "エラー検知: #{error.class}"
    lines = [ "**メッセージ:** #{error.message}" ]

    if context.present?
      lines << "**コントローラー:** #{context[:controller]}##{context[:action]}" if context[:controller]
      lines << "**ユーザー:** #{context[:user]}" if context[:user]
      lines << "**URL:** #{context[:method]} #{context[:path]}" if context[:path]
    end

    backtrace_summary = error.backtrace&.first(3)&.join("\n")
    lines << "**バックトレース:**\n```\n#{backtrace_summary}\n```" if backtrace_summary

    lines << "**発生時刻:** #{Time.current.strftime('%Y-%m-%d %H:%M:%S JST')}"

    notify(
      title: title,
      body: lines.join("\n\n"),
      webhook_url: ERROR_WEBHOOK_URL
    )
  end
end
