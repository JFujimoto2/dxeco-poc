Rails.error.subscribe(ErrorSubscriber.new) if Rails.env.production?
