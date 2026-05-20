# frozen_string_literal: true

class UsersController < BaseController
  before_action :find_user, only: %i[show edit update lock unlock]

  def index
    @users = User.by_search(filter_params[:search])
                 .page(filter_params[:page])
                 .per(filter_params[:per])
                 .order(:id)
  end

  def show
    @user = User.includes([ versions: :item ]).find(params[:id])
    @versions = @user.versions
  end

  def lock
    redirect_to @user and return if @user.lock_access!

    render :show
  end

  def unlock
    redirect_to @user and return if @user.unlock_access!

    render :show
  end

  def edit; end

  def update
    redirect_to @user, notice: "Updated successfully" and return if @user.update(user_params)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@user, partial: "users/form", locals: { user: @user }) }
      format.html { render :edit }
    end
  end

  def turbo_modal; end

  private

  def filter_params
    params.permit(:search, :status, :page, :per)
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end

  def find_user
    @user = User.find(params[:id])
  end
end
