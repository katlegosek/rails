# frozen_string_literal: true

ruby "3.4.9"

gem "rails", "~> 8.1.0"
gem "puma", "~> 6.6"
gem "bootsnap", "~> 1.18", require: false
gem "thruster", require: false

gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]

gem "propshaft"
gem "image_processing"
gem "importmap-rails", "~> 2.0"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "hotwire-spark"
gem "tailwindcss-rails", "~> 4.0"
gem "rubyzip", "~> 2.3"
gem "tailwindcss-ruby", "~> 4.1"
gem "tailwind_merge"
gem "view_component", "~> 4.11"
gem "view_component-contrib"
gem "dry-initializer"
gem "dry-effects"

gem "pg", "~> 1.5"
gem "solid_cache", "~> 1.0"
gem "solid_cable", "~> 3.0"
gem "solid_queue", "~> 1.0"
gem "mission_control-jobs", "~> 1.1"

gem "active_model_otp", "~> 2.3"
gem "devise", "~> 5.0"
gem "doorkeeper", "~> 5.8"
gem "doorkeeper-jwt", "~> 0.4"
gem "rack-cors", "~> 2.0"

# TODO: Revisit active_model_serializers before building API serializers.
gem "active_model_serializers", "~> 0.10"
gem "kaminari", "~> 1.2"
gem "paper_trail", "~> 17.0"

gem "faraday"

gem "rack-attack", "~> 6.7"
gem "lograge"

group :development, :test do
  gem "brakeman"
  gem "byebug"
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem "dotenv-rails", "~> 3.1"

  gem "capybara"
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem "shoulda-context", "~> 3.0.0.rc1"
  gem "shoulda-matchers"
  gem "simplecov", "~> 0.22.0", require: false
  gem "rubocop-rails", require: false
  gem "webmock"
  gem "webdrivers"
  gem "faker"

  gem "amazing_print"
end

group :development do
  gem "web-console"

  gem "better_errors"
  gem "binding_of_caller"

  gem "rack-mini-profiler"
  gem "memory_profiler"
  gem "stackprof"

  gem "activerecord-import"

  gem "letter_opener"
  gem "letter_opener_web"

  gem "lookbook"

  gem "rubocop-rails-omakase", require: false
end
