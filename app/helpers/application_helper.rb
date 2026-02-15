module ApplicationHelper
  WEEKDAYS_JA = %w[日 月 火 水 木 金 土].freeze

  def weekday_label(date)
    return "" unless date
    "(#{WEEKDAYS_JA[date.wday]})"
  end

  def format_date_with_weekday(date)
    return "" unless date
    "#{date.strftime('%Y/%m/%d')} (#{WEEKDAYS_JA[date.wday]})"
  end

  def safe_url_link(url)
    return "-" unless url.present?

    uri = URI.parse(url)
    if uri.scheme.in?(%w[http https])
      link_to url, url, target: "_blank", rel: "noopener"
    else
      h(url)
    end
  rescue URI::InvalidURIError
    h(url)
  end
end
