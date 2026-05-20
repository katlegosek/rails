# frozen_string_literal: true

class Providers::ClickatellProvider < Providers::BaseProvider
  def initialize
    @type = "clickatell"
  end

  def send(message, recipient, _options: {})
    mobile = format_mobile(recipient.mobile_number)

    connection.post sms_url do |req|
      req.body = params(mobile, message)
    end
  end

  private

  def connection
    Faraday.new(
      url: base_url,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => api_key
      }
    ) do |f|
      f.use Faraday::Response::RaiseError
      f.response :logger
      f.adapter Faraday.default_adapter
      f.options.timeout = timeout_seconds
      f.options.open_timeout = open_timeout_seconds
    end
  end

  def timeout_seconds
    5
  end

  def open_timeout_seconds
    5
  end

  def api_key
    Rails.application.credentials.dig(:clickatell, :api_key)
  end

  def base_url
    "https://platform.clickatell.com"
  end

  def sms_url
    "/messages"
  end

  def params(mobile, content)
    JSON.generate(to: [ mobile ], content:).to_json
  end
end
