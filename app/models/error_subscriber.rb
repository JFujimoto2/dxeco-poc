class ErrorSubscriber
  THROTTLE_PERIOD = 5.minutes

  def report(error, handled:, severity:, context:, source: nil)
    return unless severity == :error && !handled

    cache_key = "error_notified:#{error.class}:#{error.message}"
    return if Rails.cache.exist?(cache_key)

    Rails.cache.write(cache_key, true, expires_in: THROTTLE_PERIOD)

    TeamsNotifier.notify_error(error: error, context: context)
  rescue => e
    Rails.logger.error "[ErrorSubscriber] Failed to send notification: #{e.message}"
  end
end
