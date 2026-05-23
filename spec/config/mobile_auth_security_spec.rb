# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile auth security configuration", type: :request do
  describe "JWT signing secret" do
    it "is configured and non-blank in the test environment" do
      expect(defined?(JWT_SIGNING_SECRET)).to eq("constant")
      expect(JWT_SIGNING_SECRET).to be_a(String)
      expect(JWT_SIGNING_SECRET).not_to be_blank
    end

    it "fails fast in production when no secret is configured" do
      stub_const("ENV", ENV.to_h.except(MobileAuth::JwtSigningSecret::ENV_KEY))

      allow(Rails.application.credentials).to receive(:dig).with(:doorkeeper, :jwt_secret).and_return(nil)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect { MobileAuth::JwtSigningSecret.fetch! }.to raise_error(RuntimeError, /not set/)
    end
  end

  describe "Doorkeeper grant flows" do
    it "does not enable the password grant" do
      expect(Doorkeeper.configuration.grant_flows).not_to include("password")
    end

    it "uses Doorkeeper::JWT as the access token generator" do
      expect(Doorkeeper.configuration.access_token_generator).to eq("::Doorkeeper::JWT")
    end

    it "issues access tokens that expire in 2 hours" do
      expect(Doorkeeper.configuration.access_token_expires_in).to eq(2.hours)
    end

    it "has refresh tokens enabled" do
      expect(Doorkeeper.configuration.refresh_token_enabled?).to be(true)
    end
  end

  describe "Fetza Mobile OAuth application" do
    let!(:_app) do
      Doorkeeper::Application.find_or_create_by!(name: MobileAuth::TokenIssuer::MOBILE_APP_NAME) do |application|
        application.uid = "fetza-mobile-test"
        application.secret = "test-secret-not-shared-with-mobile"
        application.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
        application.confidential = false
        application.scopes = ""
      end
    end

    it "is configured as a public client" do
      app = Doorkeeper::Application.find_by!(name: MobileAuth::TokenIssuer::MOBILE_APP_NAME)
      expect(app.confidential).to be(false)
    end

    it "does not return the application secret in the JWT header or login payload" do
      user = create(:user, email: "secret-leak-check@fetza.test", password: "password123")

      post "/api/mobile/v1/auth/login",
        params: { email: user.email, password: "password123" },
        as: :json

      body = response.parsed_body
      # The mobile app must never receive the OAuth application secret.
      expect(body.to_s).not_to include("test-secret-not-shared-with-mobile")

      # The JWT `kid` header references the application UID (not the secret).
      access_token = body["access_token"]
      jwt_header_b64 = access_token.split(".").first
      jwt_header = JSON.parse(Base64.urlsafe_decode64(jwt_header_b64))
      expect(jwt_header).to include("kid" => "fetza-mobile-test")
      expect(jwt_header.to_s).not_to include("test-secret-not-shared-with-mobile")
    end
  end
end
