# frozen_string_literal: true

# JWT signing configuration for Doorkeeper access tokens.
#
# Where the signing secret comes from
# -----------------------------------
# In order of precedence:
#   1. ENV["DOORKEEPER_JWT_SECRET"]                 (preferred for ops/PaaS)
#   2. Rails.application.credentials.dig(:doorkeeper, :jwt_secret)
#   3. Rails.application.secret_key_base            (development/test fallback only)
#
# Rotating the secret
# -------------------
# Rotating invalidates all currently issued access tokens. Refresh tokens are
# stored server-side (not JWTs), so clients can recover by exchanging their
# refresh token at POST /api/mobile/v1/auth/refresh. To rotate:
#   1. Generate a strong, random key:  `bundle exec rails secret`
#   2. Update credentials/ENV and redeploy.
#   3. (Optional) Bulk-revoke active tokens via
#      `Doorkeeper::AccessToken.update_all(revoked_at: Time.current)`.
#
# Algorithm choice
# ----------------
# HS512 (HMAC-SHA-512 with a symmetric secret). The mobile app and API run in
# the same trust boundary (we are both issuer and verifier), so a strong
# symmetric secret is sufficient. If we later need third parties to verify
# tokens without sharing the secret, switch to RS256 + asymmetric keys here.
module MobileAuth
  module JwtSigningSecret
    ENV_KEY = "DOORKEEPER_JWT_SECRET"

    def self.fetch!
      candidate = from_env || from_credentials

      if candidate.blank?
        if Rails.env.production?
          raise <<~MSG.squish
            #{ENV_KEY} (or credentials.doorkeeper.jwt_secret) is not set.
            Mobile API JWT signing requires an explicit, long, random secret in production.
          MSG
        end

        # Development/test fallback: derive from secret_key_base so the app boots
        # without extra setup. NEVER relied upon in production.
        candidate = Rails.application.secret_key_base
      end

      candidate.to_s
    end

    def self.from_env
      ENV[ENV_KEY].presence
    end

    def self.from_credentials
      Rails.application.credentials.dig(:doorkeeper, :jwt_secret).presence
    rescue StandardError
      nil
    end
  end
end

JWT_SIGNING_SECRET = MobileAuth::JwtSigningSecret.fetch!.freeze

Doorkeeper::JWT.configure do
  # The payload baked into each access token. We keep it intentionally minimal:
  # the API always re-loads the user from `token.resource_owner_id` before
  # acting, so the JWT body is informational, not authoritative.
  token_payload do |opts|
    user = User.find_by(id: opts[:resource_owner_id])

    {
      iss: "fetza-mobile-api",
      iat: Time.current.utc.to_i,
      jti: SecureRandom.uuid,
      sub: opts[:resource_owner_id],
      user: user ? { id: user.id, email: user.email } : nil
    }
  end

  token_headers do |opts|
    { kid: opts[:application][:uid] }
  end

  # The OAuth application's secret is NOT used to sign JWTs. The mobile client
  # is public (confidential: false) and does not hold a client secret.
  use_application_secret false

  secret_key JWT_SIGNING_SECRET
  signing_method :hs512
end
