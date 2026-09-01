require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Rubyprice
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.factory_bot dir: "spec/factories"
      g.assets false
      g.helper false
    end

    config.active_job.queue_adapter = :sidekiq

    config.middleware.use Rack::Attack

    config.time_zone = "UTC"

    # Crawler-wide configuration, overridable via environment variables.
    config.x.crawler_user_agent = ENV.fetch("CRAWLER_USER_AGENT", "RubyPriceBot/1.0 (+https://rubyprice.example.com/bot)")
    config.x.crawler_timeout_seconds = ENV.fetch("CRAWLER_TIMEOUT_SECONDS", 8).to_i
    config.x.crawler_max_response_bytes = ENV.fetch("CRAWLER_MAX_RESPONSE_BYTES", 3 * 1024 * 1024).to_i
  end
end
