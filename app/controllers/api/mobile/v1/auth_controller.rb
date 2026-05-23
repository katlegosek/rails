# frozen_string_literal: true

class Api::Mobile::V1::AuthController < Api::Mobile::V1::BaseController
  # login/refresh/logout are public:
  #   - login   - no token to authenticate yet
  #   - refresh - uses a refresh token, not an access token
  #   - logout  - tolerant; revokes the presented token if present, otherwise no-op
  skip_before_action :authenticate_mobile_user!, only: %i[login refresh logout]

  INVALID_LOGIN_MESSAGE = "Invalid email or password."

  def login
    email = params.require(:email).to_s.strip.downcase
    password = params.require(:password).to_s

    user = User.find_by("LOWER(email) = ?", email)

    # Generic message for both "no such user" and "wrong password" so we
    # never reveal which emails are registered.
    unless user&.access_locked? == false && user&.valid_password?(password)
      register_failed_login_attempt(user)
      return render_unauthorized(INVALID_LOGIN_MESSAGE)
    end

    reset_failed_login_attempts(user)
    user.update_tracked_fields!(request) rescue nil

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

  # Single-use refresh tokens — see MobileAuth::TokenIssuer#refresh.
  def refresh
    raw_refresh_token = params.require(:refresh_token).to_s
    access_token = MobileAuth::TokenIssuer.refresh(raw_refresh_token)

    return render_unauthorized("Invalid or expired refresh token") unless access_token

    user = User.find_by(id: access_token.resource_owner_id)
    return render_unauthorized("Invalid or expired refresh token") unless user

    render json: auth_session_payload(access_token: access_token, user: user), status: :ok
  end

  private

  # Manually maintain Devise's :lockable counters for the mobile login path.
  # We can't go through Devise's `valid_for_authentication?` here because
  # `User#active_for_authentication?` is admin-only (used by the web admin
  # sign-in) and would reject regular mobile users.
  def register_failed_login_attempt(user)
    return unless user&.respond_to?(:failed_attempts)

    user.failed_attempts = (user.failed_attempts || 0) + 1
    if user.failed_attempts >= User.maximum_attempts && !user.access_locked?
      user.lock_access!(send_instructions: false)
    else
      user.save(validate: false)
    end
  end

  def reset_failed_login_attempts(user)
    return unless user.respond_to?(:failed_attempts)
    return if user.failed_attempts.to_i.zero?

    user.update_columns(failed_attempts: 0, unlock_token: nil, locked_at: nil)
  end
end
