# frozen_string_literal: true

class NotificationsController < BaseController
  before_action :find_notification, only: %i[destroy]

  def index
    @notifications = Notification.by_search(filter_params[:search])
                                 .order(id: :desc)
                                 .page(params[:page])
                                 .per(params[:per])
  end

  def new
    @notification = Notification.new
  end

  def create
    @notification = Notification.create(notification_params)

    redirect_to notification_path(@notification), notice: "Created successfully" and return if @notification

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("new_notification", partial: "notifications/form", locals: { notification: @notification }) }
      format.html { render :new }
    end
  end

  def show
    @notification = Notification.includes(notifications_users: :user)
                                .find(params[:id])
  end

  def destroy; end

  private

  def notification_params
    params.require(:notification).permit(:message, user_ids: [])
  end

  def filter_params
    params.permit(:page, :per, :search)
  end

  def find_notification
    @notification = Notification.find(params[:id])
  end
end
