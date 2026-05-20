# frozen_string_literal: true

class BillParticipant < ApplicationRecord
  belongs_to :bill

  has_many :item_assignments, dependent: :destroy

  validates :name, presence: true
  validates :seat_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
