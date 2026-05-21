# frozen_string_literal: true

class Api::Mobile::V1::AuthController < Api::Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!, only: %i[login refresh logout]

  def login
    email = params.require(:email).to_s.strip.downcase
    password = params.require(:password).to_s

    user = User.find_by("LOWER(email) = ?", email)

    unless user&.valid_password?(password)
      return render_unauthorized("Invalid email or password.")
    end

    access_token = MobileAuth::TokenIssuer.issue_for(user)

    render json: auth_session_payload(access_token: access_token, user: user), status: :ok
  end

  def logout
    revoke_bearer_access_token_if_present

    render json: { success: true }, status: :ok
  end

  def me
    render json: { user: user_payload(current_mobile_user) }, status: :ok
  end

  def refresh
    raw_refresh_token = params.require(:refresh_token).to_s
    access_token = MobileAuth::TokenIssuer.refresh(raw_refresh_token)

    unless access_token
      return render_unauthorized("Invalid or expired refresh token")
    end

    user = User.find_by(id: access_token.resource_owner_id)

    unless user
      return render_unauthorized("Invalid or expired refresh token")
    end

    render json: auth_session_payload(access_token: access_token, user: user), status: :ok
  end
end
