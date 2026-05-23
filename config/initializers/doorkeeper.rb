# frozen_string_literal: true

# Doorkeeper configuration for the Fetza mobile API.
#
# - The mobile app does NOT use the OAuth authorization or token endpoints
#   directly. Tokens are issued through our custom controllers under
#   /api/mobile/v1/auth/*, which call MobileAuth::TokenIssuer to mint
#   Doorkeeper access tokens (and refresh tokens) for the "Fetza Mobile"
#   public OAuth application.
#
# - JWT signing configuration lives in `config/initializers/doorkeeper_jwt.rb`
#   so that the signing secret is read explicitly from credentials/ENV and
#   we fail fast in production if it is missing.
#
# - To migrate to Authorization Code + PKCE in the future:
#     1. Add `authorization_code` to `grant_flows` below.
#     2. Keep `force_pkce` enabled (already set).
#     3. Mount only `:authorizations` and `:tokens` in `routes.rb`.
#     4. Stop using the custom `/api/mobile/v1/auth/login` endpoint.
Doorkeeper.configure do
  orm :active_record

  # ---------------------------------------------------------------------------
  # Resource owner lookup
  # ---------------------------------------------------------------------------
  # Used only by the standard /oauth/token password grant. We keep this defined
  # so that, if password grant is ever re-enabled, it still goes through Devise's
  # `valid_for_authentication?` (which respects lockable / role checks).
  #
  # The mobile app does NOT hit this code path today — see
  # Api::Mobile::V1::AuthController#login instead.
  resource_owner_from_credentials do
    user = User.find_for_database_authentication(email: params[:username].to_s.strip.downcase)
    next nil unless user && user.deleted_at.nil?

    user.update_tracked_fields!(request) rescue nil
    user if user.valid_for_authentication? { user.valid_password?(params[:password]) }
  end

  # ---------------------------------------------------------------------------
  # Token lifetimes
  # ---------------------------------------------------------------------------
  # Access tokens expire after 2 hours; refresh tokens let the mobile app
  # silently obtain a new access token without re-prompting for credentials.
  access_token_expires_in 2.hours
  authorization_code_expires_in 10.minutes

  # ---------------------------------------------------------------------------
  # Refresh tokens
  # ---------------------------------------------------------------------------
  # Refresh tokens are enabled. Rotation is implemented in
  # MobileAuth::TokenIssuer#refresh: the old access token is revoked the moment
  # a new one is issued, which also invalidates the old refresh token (so each
  # refresh token is single-use).
  use_refresh_token

  # ---------------------------------------------------------------------------
  # Token generator
  # ---------------------------------------------------------------------------
  # Access tokens are JWTs (see doorkeeper_jwt.rb for signing config).
  access_token_generator "::Doorkeeper::JWT"

  # ---------------------------------------------------------------------------
  # Grant flows
  # ---------------------------------------------------------------------------
  # We deliberately enable an empty grant_flows list. The mobile app uses our
  # custom /api/mobile/v1/auth/login endpoint (which issues tokens directly via
  # MobileAuth::TokenIssuer.issue_for), not Doorkeeper's /oauth/token. This
  # closes Doorkeeper's public OAuth surface entirely.
  #
  # If we add web/PKCE support later, change this to %w[authorization_code].
  grant_flows %w[]

  # If/when we re-introduce authorization_code, require PKCE for all public
  # clients. This is a no-op while grant_flows is empty.
  force_pkce

  # ---------------------------------------------------------------------------
  # SSL
  # ---------------------------------------------------------------------------
  # Force HTTPS redirect URIs outside of development/test.
  force_ssl_in_redirect_uri !(Rails.env.development? || Rails.env.test?)

  # ---------------------------------------------------------------------------
  # Auth errors
  # ---------------------------------------------------------------------------
  # Leave Doorkeeper's default JSON error handling for any /oauth/* requests
  # that slip through. All mobile API endpoints render errors through
  # Api::Mobile::V1::BaseController#render_api_error instead.
end
