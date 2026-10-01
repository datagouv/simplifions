Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.environment = Rails.env
  config.enabled_environments = %w[staging production]
end
