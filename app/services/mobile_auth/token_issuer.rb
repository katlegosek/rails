# frozen_string_literal: true

module MobileAuth
  # Issues, validates, and rotates Doorkeeper access tokens for the
  # "Fetza Mobile" public OAuth application.
  #
  # All tokens are JWTs (see config/initializers/doorkeeper_jwt.rb).
  # Refresh tokens are stored server-side (not JWTs); see #refresh below
  # for the rotation behaviour.
  class TokenIssuer
    MOBILE_APP_NAME = "Fetza Mobile"

    class MissingMobileApplication < StandardError; end

    class << self
      def mobile_application
        Doorkeeper::Application.find_by(name: MOBILE_APP_NAME) || raise(
          MissingMobileApplication,
          "Doorkeeper application '#{MOBILE_APP_NAME}' is missing. Run `bin/rails db:seed` " \
          "or create it manually (see docs/mobile_auth.md)."
        )
      end

      # Creates a fresh access token (and refresh token) for the given user.
      def issue_for(user)
        Doorkeeper::AccessToken.create!(
          application: mobile_application,
          resource_owner_id: user.id,
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: true,
          scopes: ""
        )
      end

      # Looks up the access token by its raw value and returns it only when it
      # is "accessible" (not expired, not revoked). Safe to call with nil.
      def find_accessible_access_token(raw_access_token)
        return if raw_access_token.blank?

        token = Doorkeeper::AccessToken.by_token(raw_access_token)
        return unless token&.accessible?

        token
      end

      # Refresh token rotation:
      #
      # We revoke the previous access token immediately when a new one is
      # issued. Because the refresh token lives on the same access-token row,
      # revoking the access token also makes the refresh token unusable —
      # giving us single-use refresh tokens with no extra bookkeeping.
      #
      # Returns the new access token, or nil if the refresh token is missing/
      # expired/revoked or its resource owner no longer exists.
      def refresh(raw_refresh_token)
        return if raw_refresh_token.blank?

        previous = Doorkeeper::AccessToken.by_refresh_token(raw_refresh_token.to_s)
        return unless previous&.accessible?

        user = User.find_by(id: previous.resource_owner_id)
        return unless user
        return if user.respond_to?(:deleted_at) && user.deleted_at.present?

        previous.revoke
        issue_for(user)
      end
    end
  end
end
