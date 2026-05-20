# frozen_string_literal: true

class ReceiptImage < ApplicationRecord
  belongs_to :receipt

  has_one_attached :image

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :capture_type, presence: true
end
