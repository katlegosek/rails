# frozen_string_literal: true

# Auth-related JSON payloads for the mobile API.
#
# Lives in a dedicated concern so that adding token/session fields does not
# require touching bill/receipt presenters, and so we never accidentally
# expose Devise/Doorkeeper internals (encrypted_password, reset tokens,
# OAuth application secrets, etc.).
module Api::Mobile::V1::ResponsePayloads::AuthPayloads
  extend ActiveSupport::Concern

  private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.try(:first_name),
      last_name: user.try(:last_name),
      full_name: user.try(:full_name).presence || user.email
    }
  end

  def auth_session_payload(access_token:, user:)
    {
      access_token: access_token.token,
      refresh_token: access_token.refresh_token,
      token_type: "Bearer",
      expires_in: access_token.expires_in,
      user: user_payload(user)
    }
  end
end
