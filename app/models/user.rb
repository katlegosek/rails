# frozen_string_literal: true

class User < ApplicationRecord
  include Deletable
  include OtpResettable
  include User::Destroyable
  include User::Authentication

  has_paper_trail ignore: %i[encrypted_password reset_password_token reset_password_sent_at remember_created_at
                             sign_in_count current_sign_in_at last_sign_in_at confirmation_token confirmed_at
                             confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at otp_secret_key
                             created_at updated_at]

  enum :role, { user: "user", admin: "admin" }

  validates :first_name, :last_name, :role, presence: true

  has_many :notifications_users, dependent: :destroy
  has_many :notifications, through: :notifications_users
  has_many :bills, dependent: :destroy
  has_many :mobile_sessions, dependent: :destroy

  delegate :count, to: :unread_notifications, prefix: true

  scope :by_search, lambda { |search = nil|
    search.blank? ? all : where("first_name || last_name || email ILIKE ?", "%#{search}%")
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def unread_notifications
    notifications.where(notifications_users: { read_at: nil })
  end

  def verify_otp_period_valid?
    verify_otp_sent_at && verify_otp_sent_at.utc >= self.class.reset_password_within.ago.utc
  end
end
