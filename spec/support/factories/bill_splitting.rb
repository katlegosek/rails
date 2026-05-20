# frozen_string_literal: true

FactoryBot.define do
  factory :bill do
    user
    status { :draft }
  end

  factory :receipt do
    bill
    status { :draft }
  end

  factory :receipt_item do
    bill
    receipt
    sequence(:name) { |n| "Item #{n}" }
    quantity { 1 }
    unit_price_cents { 1_000 }
    total_cents { 1_000 }
    sequence(:position)
  end

  factory :receipt_adjustment do
    receipt
    sequence(:label) { |n| "Adjustment #{n}" }
    kind { :other }
    amount_cents { 100 }
    included_in_total { true }
    sequence(:position)
  end

  factory :bill_participant do
    bill
    sequence(:name) { |n| "Participant #{n}" }
    initials { "P" }
    is_host { false }
    settled { false }
  end

  factory :item_assignment do
    receipt_item
    bill_participant
    amount_cents { 1_000 }
    split_method { :equal }
  end

  factory :receipt_processing_run do
    receipt
    provider { "fake_ocr" }
    status { :pending }
  end

  factory :receipt_image do
    receipt
    sequence(:position)
    capture_type { "full" }

    after(:build) do |receipt_image|
      receipt_image.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/receipt.jpg")),
        filename: "receipt.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
