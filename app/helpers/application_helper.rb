module ApplicationHelper
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
