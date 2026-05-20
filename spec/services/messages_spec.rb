# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :worker do
  describe "BaseMessage" do
    it "should contain development" do
      ENV['RAILS_ENV'] = "development"
      expect(Messages::BaseMessage.format("Test").include?("Development")).to be_truthy
    end

    it "should contain staging" do
      ENV['RAILS_ENV'] = "staging"
      expect(Messages::BaseMessage.format("Test").include?("Staging")).to be_truthy
    end

    it "should contain nothing extra" do
      ENV['RAILS_ENV'] = "production"
      expect(Messages::BaseMessage.format("Test") == "Test").to be_truthy
    end
  end

  describe "AuthMessage" do
    it "should return the OTP message" do
      user = FactoryBot.create(:user)
      code = user.otp_code
      message = Messages::AuthMessage.otp(code)

      expect(message.include?(user.otp_code)).to be_truthy
    end

    it "should return the OTP message and an android code" do
      user = FactoryBot.create(:user)
      code = user.otp_code
      message = Messages::AuthMessage.otp(code, "android")

      expect(message.include?("android")).to be_truthy
    end
  end
end
