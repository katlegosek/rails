# frozen_string_literal: true

module ApiErrorHelpers
  def api_error(response_body)
    response_body.fetch("error")
  end
end

RSpec.configure do |config|
  config.include ApiErrorHelpers, type: :request
end
