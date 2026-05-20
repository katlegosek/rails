# frozen_string_literal: true

require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BillSplittingApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: Rails.application.credentials.dig(:smtp, :address),
      user_name: Rails.application.credentials.dig(:smtp, :user_name),
      password: Rails.application.credentials.dig(:smtp, :password),
      port: 587,
      authentication: :plain
    }

    config.time_zone = "Africa/Johannesburg"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths << Rails.root.join("app", "views", "components")
    config.view_component.previews.paths << Rails.root.join("app", "views", "components")
    config.generators.system_tests = nil

    ActiveModelSerializers.config.adapter = :json
  end
end
