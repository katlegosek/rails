# frozen_string_literal: true

class BillParticipant < ApplicationRecord
  GUEST_TOKEN_BYTES = 32

  belongs_to :bill

  has_many :item_assignments, dependent: :destroy

  validates :name, presence: true
  validates :name, length: { maximum: 80 }
  validates :guest_token_digest, uniqueness: true, allow_nil: true
  validates :seat_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  after_save :ensure_single_host, if: :saved_change_to_is_host?

  def issue_guest_token!
    raw_token = SecureRandom.urlsafe_base64(GUEST_TOKEN_BYTES)
    update!(guest_token_digest: self.class.digest_guest_token(raw_token))
    raw_token
  end

  def self.digest_guest_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  private

  def ensure_single_host
    return unless is_host?

    bill.bill_participants.where.not(id: id).update_all(is_host: false)
  end
end
