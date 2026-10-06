require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Simplifions
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :fr
    config.active_model.i18n_customize_full_message = true
    config.action_view.field_error_proc = ->(html_tag, _instance) { html_tag }

    config.active_storage.service = :db

    config.active_job.queue_adapter = :solid_queue

    config.x.contact_email = "contact-simplifions@data.gouv.fr"

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Paris'
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
