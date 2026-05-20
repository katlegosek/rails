# frozen_string_literal: true

module OtpResettable
  extend ActiveSupport::Concern

  MAX_FAILED_OTP_ATTEMPTS = 3
  ALLOW_DEFAULT_OTP = Rails.env.development? || Rails.env.test?

  included do
    has_one_time_password after_column_name: :last_otp_at

    def verify_otp(otp)
      return reset_failed_otp_attempts if authenticate_otp(otp, drift: 60) || (ALLOW_DEFAULT_OTP && otp == "123456")

      increment_failed_otp_attempts
      false
    end

    private

    def reset_failed_otp_attempts
      update(failed_otp_attempts: 0)
    end

    def increment_failed_otp_attempts
      return expire_otp if failed_otp_attempts + 1 >= MAX_FAILED_OTP_ATTEMPTS

      update(failed_otp_attempts: failed_otp_attempts + 1)
    end

    def expire_otp
      update(otp_secret_key: self.class.otp_random_secret, failed_otp_attempts: 0)
    end
  end
end
