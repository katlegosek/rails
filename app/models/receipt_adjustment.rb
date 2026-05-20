# frozen_string_literal: true

class ReceiptAdjustment < ApplicationRecord
  belongs_to :receipt

  enum :kind, {
    subtotal: "subtotal",
    tax: "tax",
    service_fee: "service_fee",
    tip: "tip",
    discount: "discount",
    rounding: "rounding",
    delivery_fee: "delivery_fee",
    other: "other"
  }

  validates :label, presence: true
  validates :kind, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
