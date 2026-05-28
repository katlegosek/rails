# frozen_string_literal: true

# Serializes the public-facing User attributes the mobile app needs.
# Mirrors the previous `user_payload` helper exactly so /auth/login,
# /auth/me, and /auth/refresh keep the same JSON shape.
class Api::Mobile::V1::AuthUserSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      email: object.email,
      first_name: object.try(:first_name),
      last_name: object.try(:last_name),
      full_name: object.try(:full_name).presence || object.email
    }
  end
end
