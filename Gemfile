source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4"
gem "json", "< 3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
gem "view_component"
# Chain-of-command pipelines (Grist import)
gem "interactor"

# Suivi des erreurs (sandbox, staging, production) ; inactif sans sentry_dsn dans les credentials
gem "sentry-rails"

# Rend le markdown du catalogue Grist (HTML brut autorisé, nettoyé par sanitize dans ApplicationHelper#markdown)
gem "commonmarker"

# Store Active Storage blobs in PostgreSQL, shared by every host [https://github.com/blocknotes/active_storage_db]
gem "active_storage_db"

# Authentification de l'administration : comptes locaux, sans inscription ni e-mail
gem "devise"

gem "strong_migrations"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapter for Rails.cache
gem "solid_cache"

gem "solid_queue", "~> 1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false

  gem "active_record_doctor"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  gem "rspec-rails"
  gem "rspec-its"
  gem "rspec-collection_matchers"
  gem "rspec-json_expectations"
  gem "shoulda-matchers"
  gem "webmock"
  gem "timecop"
  gem "simplecov", require: false
  gem "simplecov-cobertura"
  gem "super_diff"
  gem "rails-controller-testing"

  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
