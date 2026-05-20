# frozen_string_literal: true

FactoryBot.define do
  sequence :email do |n|
    "user+#{n}@fetza.test"
  end

  factory :user, class: User do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name

    email { Faker::Internet.email(name: "#{Faker::Name.first_name} #{Faker::Name.last_name}") }
    password { 'Password1!' }
    role { 'user' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    mobile_number { Faker::PhoneNumber.cell_phone }
    otp_secret_key { User.otp_random_secret }
    confirmed_at { Time.zone.now }
  end
end
