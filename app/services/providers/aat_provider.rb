# frozen_string_literal: true

class Providers::AatProvider < Providers::BaseProvider
  def initialize
    @type = "aat"
  end

  def send(message, recipient, _options: {})
    mobile = format_mobile(recipient.mobile_number)

    connection.get sms_url do |req|
      req.params = params(mobile, message)
      req
    end
  end

  private

  def connection
    Faraday.new(url: base_url) do |f|
      f.use FaradayMiddleware::FollowRedirects, limit: 3
      f.adapter Faraday.default_adapter
      f.basic_auth aat_username, aat_password
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

  def aat_username
    Rails.application.credentials.dig(:aat, :username)
  end

  def aat_password
    Rails.application.credentials.dig(:aat, :password)
  end

  def base_url
    url = Rails.application.credentials.dig(:aat, :sms_url)
    url.gsub("username", aat_username)
    url.gsub("password", aat_password)
  end

  def sms_url
    "/xml/send"
  end

  def params(number, message)
    {
      number:,
      message:
    }
  end
end
