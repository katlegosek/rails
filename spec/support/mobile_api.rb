# frozen_string_literal: true

module MobileApiRequestHelpers
  def mobile_auth_headers
    @mobile_auth_headers || {}
  end

  def authorize_mobile_user(user)
    raw_access_token = SecureRandom.urlsafe_base64(32)
    raw_refresh_token = SecureRandom.urlsafe_base64(32)

    MobileSession.create!(
      user: user,
      access_token_digest: MobileSessions::TokenIssuer.digest(raw_access_token),
      refresh_token_digest: MobileSessions::TokenIssuer.digest(raw_refresh_token),
      access_token_expires_at: 1.hour.from_now,
      refresh_token_expires_at: 30.days.from_now
    )

    @mobile_auth_headers = { "Authorization" => "Bearer #{raw_access_token}" }
    @mobile_raw_access_token = raw_access_token
    @mobile_raw_refresh_token = raw_refresh_token
  end

  %i[get post patch put delete].each do |http_method|
    define_method(http_method) do |path, **kwargs|
      headers = mobile_auth_headers.merge(kwargs[:headers] || {})
      super(path, **kwargs, headers: headers)
    end
  end
end

RSpec.shared_context "mobile api current user" do
  let!(:user) { create(:user) }

  before do
    authorize_mobile_user(user)
  end
end

RSpec.configure do |config|
  config.include MobileApiRequestHelpers, type: :request

  config.include_context "mobile api current user",
    file_path: %r{spec/requests/api/mobile/v1/(?!users|auth)}
end
