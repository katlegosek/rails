# frozen_string_literal: true

FactoryBot.define do
  factory :doorkeeper_application, class: Doorkeeper::Application do
    name { 'test_application' }
    redirect_uri { 'https://localhost:3000' }
    scopes { 'read write' }
  end

  factory :access_token, class: Doorkeeper::AccessToken do
    scopes { 'read write' }
  end
end
