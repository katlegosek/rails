# frozen_string_literal: true

class Notification < ApplicationRecord
  after_create_commit :broadcast_notification

  validates :message, presence: true

  has_many :notifications_users, dependent: :destroy
  has_many :users, through: :notifications_users

  scope :by_search, lambda { |search = nil|
    search.blank? ? all : where("message ILIKE ?", "%#{search}%")
  }

  def notifications_user(current_user)
    @notifications_user ||= notifications_users.find_by(user: current_user)
  end

  def read!(current_user)
    notifications_user(current_user)&.read!
  end

  def read?(current_user)
    notifications_user(current_user)&.read?
  end

  private

  def broadcast_notification
    users.each do |user|
      unread_count = user.unread_notifications.count

      broadcast_replace_to "broadcast_to_user_#{user.id}",
                           target: "notifications-count",
                           html: ApplicationController.render(Atoms::Badge::Component.new(count: user.unread_notifications_count))

      broadcast_update_to "broadcast_to_user_#{user.id}",
                          target: "dropdown-notification-button",
                          html: ApplicationController.render(Atoms::Badge::Component.new(count: user.unread_notifications_count))

      if unread_count <= 1
        broadcast_replace_to "broadcast_to_user_#{user.id}",
                             target: "notification-list",
                             html: ApplicationController.render(Molecules::NotificationNavItem::Component.new(notification: self))
      else
        broadcast_append_to "broadcast_to_user_#{user.id}",
                            target: "notification-list",
                            html: ApplicationController.render(Molecules::NotificationNavItem::Component.new(notification: self))
      end
    end
  end
end
