# frozen_string_literal: true

module MobileSessions
  class TokenIssuer
    ACCESS_TOKEN_TTL = 1.hour
    REFRESH_TOKEN_TTL = 30.days
    EXPIRES_IN_SECONDS = ACCESS_TOKEN_TTL.to_i

    class << self
      def digest(raw_token)
        Digest::SHA256.hexdigest(raw_token)
      end

      def issue_for(user)
        raw_access_token = generate_raw_token
        raw_refresh_token = generate_raw_token

        session = MobileSession.create!(
          user: user,
          access_token_digest: digest(raw_access_token),
          refresh_token_digest: digest(raw_refresh_token),
          access_token_expires_at: ACCESS_TOKEN_TTL.from_now,
          refresh_token_expires_at: REFRESH_TOKEN_TTL.from_now
        )

        [ session, raw_access_token, raw_refresh_token ]
      end

      def find_active_by_access_token(raw_access_token)
        return if raw_access_token.blank?

        session = MobileSession.active.find_by(access_token_digest: digest(raw_access_token))
        return if session.blank?
        return if session.access_token_expired?

        session
      end

      def find_active_by_refresh_token(raw_refresh_token)
        return if raw_refresh_token.blank?

        session = MobileSession.active.find_by(refresh_token_digest: digest(raw_refresh_token))
        return if session.blank?
        return if session.refresh_token_expired?

        session
      end

      private

      def generate_raw_token
        SecureRandom.urlsafe_base64(32)
      end
    end
  end
end
