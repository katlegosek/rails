# frozen_string_literal: true

class ItemAssignment < ApplicationRecord
  belongs_to :receipt_item
  belongs_to :bill_participant

  enum :split_method, {
    equal: "equal",
    custom: "custom"
  }

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :split_method, presence: true
  validates :receipt_item_id, uniqueness: { scope: :bill_participant_id }
end
