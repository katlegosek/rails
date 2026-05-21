# frozen_string_literal: true

class MobileSession < ApplicationRecord
  belongs_to :user

  validates :access_token_digest, presence: true, uniqueness: true
  validates :refresh_token_digest, presence: true, uniqueness: true
  validates :access_token_expires_at, :refresh_token_expires_at, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def revoked?
    revoked_at.present?
  end

  def access_token_expired?
    access_token_expires_at < Time.current
  end

  def refresh_token_expired?
    refresh_token_expires_at < Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end
end
