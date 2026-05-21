# frozen_string_literal: true

module MobileApiRequestHelpers
  def mobile_auth_headers
    @mobile_auth_headers || {}
  end

  def ensure_mobile_oauth_application!
    Doorkeeper::Application.find_or_create_by!(name: "Fetza Mobile") do |application|
      application.uid = "fetza-mobile-test"
      application.secret = Doorkeeper::OAuth::Helpers::UniqueToken.generate
      application.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
      application.confidential = false
      application.scopes = ""
    end
  end

  def authorize_mobile_user(user)
    ensure_mobile_oauth_application!

    access_token = Doorkeeper::AccessToken.create!(
      application: Doorkeeper::Application.find_by!(name: "Fetza Mobile"),
      resource_owner_id: user.id,
      expires_in: Doorkeeper.configuration.access_token_expires_in,
      use_refresh_token: true,
      scopes: ""
    )

    @mobile_auth_headers = { "Authorization" => "Bearer #{access_token.token}" }
    @mobile_raw_access_token = access_token.token
    @mobile_raw_refresh_token = access_token.refresh_token
    access_token
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
    ensure_mobile_oauth_application!
    authorize_mobile_user(user)
  end
end

RSpec.configure do |config|
  config.include MobileApiRequestHelpers, type: :request

  config.include_context "mobile api current user",
    file_path: %r{spec/requests/api/mobile/v1/(?!users|auth)}
end
