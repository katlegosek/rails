# frozen_string_literal: true

FactoryBot.define do
  factory :notification, class: Notification do
    message { Faker::Alphanumeric.alpha(number: 10) }

    after(:create) do |notification|
      notification.users << FactoryBot.create_list(:user, 3)
    end
  end
end
