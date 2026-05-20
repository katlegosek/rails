# frozen_string_literal: true

class NotificationsUser < ApplicationRecord
  belongs_to :notification
  belongs_to :user

  def read!
    update(read_at: Time.zone.now)
  end

  def read?
    read_at.present?
  end
end
