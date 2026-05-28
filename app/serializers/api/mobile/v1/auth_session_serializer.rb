# frozen_string_literal: true

# Composes the auth/session response returned by login + refresh.
# Wraps a Doorkeeper::AccessToken and the owning User.
class Api::Mobile::V1::AuthSessionSerializer < Api::Mobile::V1::BaseSerializer
  def initialize(access_token:, user:)
    super(nil, access_token: access_token, user: user)
  end

  def as_json(*)
    access_token = options.fetch(:access_token)
    user = options.fetch(:user)

    {
      access_token: access_token.token,
      refresh_token: access_token.refresh_token,
      token_type: "Bearer",
      expires_in: access_token.expires_in,
      user: Api::Mobile::V1::AuthUserSerializer.new(user).as_json
    }
  end
end
