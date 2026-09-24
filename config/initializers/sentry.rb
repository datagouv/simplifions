Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.environment = Rails.env
  config.send_default_pii = false
end
