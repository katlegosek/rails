# frozen_string_literal: true

class Api::Mobile::V1::AuthController < Api::Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!, only: %i[login refresh]

  def login
    email = params.require(:email).to_s.strip.downcase
    password = params.require(:password).to_s

    user = User.find_by("LOWER(email) = ?", email)

    unless user&.valid_password?(password)
      return render_unauthorized("Invalid email or password")
    end

    _session, raw_access_token, raw_refresh_token = MobileSessions::TokenIssuer.issue_for(user)

    render json: auth_session_payload(
      raw_access_token: raw_access_token,
      raw_refresh_token: raw_refresh_token,
      user: user
    ), status: :ok
  end

  def logout
    current_mobile_session&.revoke!

    render json: { success: true }, status: :ok
  end

  def me
    render json: { user: user_payload(current_mobile_user) }, status: :ok
  end

  def refresh
    raw_refresh_token = params.require(:refresh_token).to_s
    session = MobileSessions::TokenIssuer.find_active_by_refresh_token(raw_refresh_token)

    unless session
      return render_unauthorized("Invalid or expired refresh token")
    end

    user = session.user
    session.revoke!

    _new_session, raw_access_token, raw_refresh_token = MobileSessions::TokenIssuer.issue_for(user)

    render json: auth_session_payload(
      raw_access_token: raw_access_token,
      raw_refresh_token: raw_refresh_token,
      user: user
    ), status: :ok
  end
end
