# frozen_string_literal: true

class BillParticipant < ApplicationRecord
  belongs_to :bill

  has_many :item_assignments, dependent: :destroy

  validates :name, presence: true
  validates :seat_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  after_save :ensure_single_host, if: :saved_change_to_is_host?

  private

  def ensure_single_host
    return unless is_host?

    bill.bill_participants.where.not(id: id).update_all(is_host: false)
  end
end
