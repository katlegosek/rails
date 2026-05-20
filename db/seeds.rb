# frozen_string_literal: true

if Rails.env.production?
  Doorkeeper::Application.create_with(
    scopes: %w[read write],
    redirect_uri: 'http://localhost:3000',
    uid: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
    secret: Doorkeeper::OAuth::Helpers::UniqueToken.generate
  ).find_or_create_by!(name: 'Template')
else
  Doorkeeper::Application.create_with(
    scopes: %w[read write],
    redirect_uri: 'http://localhost:3000',
    uid: 'nqAFzOUUniN8PCCZfzsRfMkDPIyc9KgreM96MymzPMA',
    secret: 'jmNJE31IYCEKLt5621YMw6LOCGkwbzaNL4U1SU-G__Y'
  ).find_or_create_by!(name: 'RailsViewTemplate')

  User.create_with(
    first_name: 'Default',
    last_name: 'User',
    password: 'Password1!',
    role: 'admin',
    otp_secret_key: User.otp_random_secret,
    confirmed_at: Time.zone.now
  ).find_or_create_by!(email: 'user@codehesion.co.za')

  users = []
  99.times do
    users << User.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      password: SecureRandom.base36,
      otp_secret_key: User.otp_random_secret,
      confirmed_at: Time.zone.now
    )
  end
  User.import users
end
