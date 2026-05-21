# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile auth API", type: :request do
  let(:password) { "password123" }
  let!(:auth_user) do
    create(
      :user,
      email: "dev@fetza.local",
      password: password,
      first_name: "Dev",
      last_name: "User"
    )
  end

  before { ensure_mobile_oauth_application! }

  def login_payload(email: auth_user.email, pass: password)
    { email: email, password: pass }
  end

  def auth_headers(raw_access_token)
    { "Authorization" => "Bearer #{raw_access_token}" }
  end

  describe "POST /api/mobile/v1/auth/login" do
    it "returns tokens and user on success" do
      post "/api/mobile/v1/auth/login", params: login_payload, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(body["token_type"]).to eq("Bearer")
      expect(body["expires_in"]).to eq(7200)
      expect(body["user"]).to include(
        "id" => auth_user.id,
        "email" => "dev@fetza.local",
        "first_name" => "Dev",
        "last_name" => "User",
        "full_name" => "Dev User"
      )

      token = Doorkeeper::AccessToken.by_token(body["access_token"])
      expect(token).to be_present
      expect(token).to be_accessible
      expect(token.resource_owner_id).to eq(auth_user.id)
    end

    it "returns unauthorized for invalid password" do
      post "/api/mobile/v1/auth/login",
        params: login_payload(pass: "wrong-password"),
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(api_error(response.parsed_body)).to include(
        "code" => "unauthorized",
        "message" => "Invalid email or password."
      )
    end
  end

  describe "GET /api/mobile/v1/auth/me" do
    it "returns the current user with a valid token" do
      post "/api/mobile/v1/auth/login", params: login_payload, as: :json
      token = response.parsed_body["access_token"]

      get "/api/mobile/v1/auth/me", headers: auth_headers(token)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["user"]).to include(
        "id" => auth_user.id,
        "email" => "dev@fetza.local"
      )
    end

    it "returns unauthorized without a token" do
      get "/api/mobile/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
      expect(api_error(response.parsed_body)).to include(
        "code" => "unauthorized",
        "message" => "You need to sign in to continue."
      )
    end
  end

  describe "POST /api/mobile/v1/auth/logout" do
    it "revokes the current token" do
      post "/api/mobile/v1/auth/login", params: login_payload, as: :json
      token = response.parsed_body["access_token"]

      post "/api/mobile/v1/auth/logout", headers: auth_headers(token)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("success" => true)

      get "/api/mobile/v1/auth/me", headers: auth_headers(token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/mobile/v1/auth/refresh" do
    it "returns new tokens and invalidates the old access token" do
      post "/api/mobile/v1/auth/login", params: login_payload, as: :json
      old_access = response.parsed_body["access_token"]
      refresh_token = response.parsed_body["refresh_token"]

      post "/api/mobile/v1/auth/refresh", params: { refresh_token: refresh_token }, as: :json

      expect(response).to have_http_status(:ok)
      new_access = response.parsed_body["access_token"]
      expect(new_access).to be_present
      expect(new_access).not_to eq(old_access)

      get "/api/mobile/v1/auth/me", headers: auth_headers(old_access)
      expect(response).to have_http_status(:unauthorized)

      get "/api/mobile/v1/auth/me", headers: auth_headers(new_access)
      expect(response).to have_http_status(:ok)
    end

    it "returns unauthorized for an invalid refresh token" do
      post "/api/mobile/v1/auth/refresh",
        params: { refresh_token: "not-a-valid-refresh-token" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(api_error(response.parsed_body)).to include("code" => "unauthorized")
    end
  end

  describe "protected bill endpoints" do
    it "requires a token" do
      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the authenticated user's bills" do
      own_bill = create(:bill, user: auth_user)
      create(:bill, user: create(:user))

      post "/api/mobile/v1/auth/login", params: login_payload, as: :json
      token = response.parsed_body["access_token"]

      get "/api/mobile/v1/bills", headers: auth_headers(token)

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["bills"].map { |bill| bill["id"] }
      expect(ids).to eq([ own_bill.id ])
    end
  end
end
