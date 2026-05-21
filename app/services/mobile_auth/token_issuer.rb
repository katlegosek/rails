# frozen_string_literal: true

module MobileAuth
  # Issues Doorkeeper access tokens for the Fetza mobile OAuth application.
  # Tokens are JWTs (see doorkeeper-jwt); raw values are returned once in API responses.
  class TokenIssuer
    MOBILE_APP_NAME = "Fetza Mobile"

    class << self
      def mobile_application
        Doorkeeper::Application.find_by!(name: MOBILE_APP_NAME)
      end

      def issue_for(user)
        Doorkeeper::AccessToken.create!(
          application: mobile_application,
          resource_owner_id: user.id,
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: true,
          scopes: ""
        )
      end

      def find_accessible_access_token(raw_access_token)
        token = Doorkeeper::AccessToken.by_token(raw_access_token)
        return unless token&.accessible?

        token
      end

      def refresh(raw_refresh_token)
        previous = Doorkeeper::AccessToken.by_refresh_token(raw_refresh_token.to_s)
        return unless previous&.accessible?

        user = User.find_by(id: previous.resource_owner_id)
        return unless user

        previous.revoke
        issue_for(user)
      end
    end
  end
end
