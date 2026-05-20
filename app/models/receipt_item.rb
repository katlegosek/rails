# frozen_string_literal: true

class ReceiptItem < ApplicationRecord
  belongs_to :bill
  belongs_to :receipt, optional: true

  has_many :item_assignments, dependent: :destroy

  validates :name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
end
