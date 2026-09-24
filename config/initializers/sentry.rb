Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.environment = Rails.env
end
