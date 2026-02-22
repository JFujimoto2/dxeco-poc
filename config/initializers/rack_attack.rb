class Rack::Attack
  # Login endpoint throttling: max 5 requests per 20 seconds per IP
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/dev_login" && req.post?
      req.ip
    end
  end

  throttle("auth/ip", limit: 5, period: 20.seconds) do |req|
    if req.path.start_with?("/auth/") && req.post?
      req.ip
    end
  end

  # General request throttling: max 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
      [ "リクエスト数が上限を超えました。しばらく時間をおいてから再度お試しください。" ]
    ]
  end
end
