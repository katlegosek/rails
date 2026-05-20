# frozen_string_literal: true

class Molecules::NotificationNavItem::Component < ApplicationViewComponent
  with_collection_parameter :notification_nav_item

  option :notification

  def before_render
    routes = Rails.application.routes.url_helpers

    @message = notification.message
    @icon = "inbox-notification"
    @created_at = notification.created_at.strftime("%F %R")
    @href =   routes.inbox_message_path(notification[:id])
  end

  attr_reader :message, :icon, :created_at, :href
end
