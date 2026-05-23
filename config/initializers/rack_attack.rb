# frozen_string_literal: true

# Rate limiting for the mobile API.
#
# Tuned conservatively to protect the password login endpoint from credential
# stuffing / brute force without blocking legitimate users who occasionally
# mistype their password. Devise's :lockable strategy (5 failed attempts per
# account) provides a per-account limit; the throttles below add per-IP and
# per-email limits in front of it.
#
# Rack::Attack is enabled in all environments except test (where rate-limit
# behaviour would make specs flaky). Tests that exercise the throttling can
# wrap blocks with `Rack::Attack.enabled = true`.

class Rack::Attack
  # Drop the cache store in front of Rack::Attack. Solid Cache is the default
  # in Rails 8; falls back to an in-memory cache for environments without it.
  cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  ### Throttle login attempts ###

  # Per-IP: 10 login attempts per minute.
  throttle("mobile/auth/login/ip", limit: 10, period: 1.minute) do |req|
    if req.post? && req.path == "/api/mobile/v1/auth/login"
      req.ip
    end
  end

  # Per-email: 5 login attempts per 5 minutes, regardless of source IP.
  throttle("mobile/auth/login/email", limit: 5, period: 5.minutes) do |req|
    next unless req.post? && req.path == "/api/mobile/v1/auth/login"

    email = extract_login_email(req)
    email.presence
  end

  # Per-IP refresh: 30 refresh attempts per minute. Generous enough for
  # normal token rotation but prevents abuse.
  throttle("mobile/auth/refresh/ip", limit: 30, period: 1.minute) do |req|
    if req.post? && req.path == "/api/mobile/v1/auth/refresh"
      req.ip
    end
  end

  ### Custom throttled response ###

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    retry_after = match_data[:period] || 60

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [
        {
          error: {
            code: "rate_limited",
            message: "Too many requests. Please try again in a moment."
          }
        }.to_json
      ]
    ]
  end

  def self.extract_login_email(req)
    body = req.body.read
    req.body.rewind
    return if body.blank?

    parsed = if req.content_type.to_s.include?("application/json")
      JSON.parse(body) rescue {}
    else
      Rack::Utils.parse_nested_query(body)
    end

    email = parsed.is_a?(Hash) ? parsed["email"] : nil
    email&.to_s&.strip&.downcase
  rescue StandardError
    nil
  end
end

# Disabled in test so the suite isn't slowed/flaked by throttling. Individual
# specs can flip `Rack::Attack.enabled = true` around the example if needed.
Rack::Attack.enabled = !Rails.env.test?
