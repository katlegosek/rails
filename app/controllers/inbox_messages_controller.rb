# frozen_string_literal: true

class InboxMessagesController < BaseController
  before_action :find_notification, only: %i[destroy]

  def index
    @notifications = current_user.notifications
                                 .by_search(filter_params[:search])
                                 .order(id: :desc)
                                 .page(params[:page])
                                 .per(params[:per])
  end

  def show
    @notification = current_user.notifications
                                .includes(notifications_users: :user)
                                .find(params[:id])
    @notification_link = @notification.notifications_users.where(user: current_user).first
    @notification.read!(current_user) unless @notification.read?(current_user)
  end

  def destroy; end

  private

  def filter_params
    params.permit(:page, :per, :search)
  end

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
