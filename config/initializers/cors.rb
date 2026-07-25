# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Read more: https://github.com/cyu/rack-cors

# TODO(production): Restrict CORS origins in production (not Expo dev URLs). See docs/DEV_ONLY_TODOS.md
expo_dev_origins = [
  %r{\Ahttp://localhost(:\d+)?\z},
  %r{\Ahttp://127\.0\.0\.1(:\d+)?\z},
  %r{\Aexp://localhost(:\d+)?\z},
  %r{\Aexp://127\.0\.0\.1(:\d+)?\z},
  %r{\Aexp://192\.168\.\d{1,3}\.\d{1,3}(:\d+)?\z},
  %r{\Aexp://10\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\z},
  %r{\Ahttps://[a-z0-9-]+\.exp\.direct\z}
]
configured_web_origins = [
  ENV["WEB_APP_URL"],
  ENV["FRONTEND_URL"]
].compact_blank.map { |origin| origin.delete_suffix("/") }

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*configured_web_origins, *(Rails.env.development? ? expo_dev_origins : []))

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization]
  end
end
