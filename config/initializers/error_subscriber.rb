Rails.application.config.after_initialize do
  Rails.error.subscribe(ErrorSubscriber.new) if Rails.env.production?
end
