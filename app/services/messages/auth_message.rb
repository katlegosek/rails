# frozen_string_literal: true

class Messages::AuthMessage < Messages::BaseMessage
  def self.sms_autofill_code(operating_system)
    Rails.application.credentials.dig(:sms_autofill_code, operating_system)
  end

  def self.otp(otp, operating_system = "ios")
    message = "App Name - Your One Time Pin (OTP) is #{otp}."
    code = sms_autofill_code(operating_system)
    message = "#{message}.\n\n#{code}" unless operating_system.downcase == "ios"

    format(message)
  end
end
