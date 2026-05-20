# frozen_string_literal: true

class Api::Mobile::V1::UsersController < Api::BaseController
  before_action :find_user_by_email, only: %i[forgot_password]
  before_action :find_user_by_verify_otp_token, only: :verify_otp
  before_action :find_user_by_reset_token, only: :reset_password
  before_action :validate_verify_request, only: :verify_otp
  before_action :validate_reset_request, only: :reset_password

  skip_before_action :doorkeeper_authorize!, :set_paper_trail_whodunnit, only: %i[create forgot_password verify_otp reset_password]

  def create
    user = User.new(user_params.merge(otp_secret_key: User.otp_random_secret, confirmed_at: Time.zone.now))

    return render json: user, status: :created if user.save

    render json: { errors: user.errors }, status: :unprocessable_content
  end

  def show
    render json: current_user
  end

  def update
    return render json: current_user if current_user.update(user_params.except(:password))

    render json: { errors: current_user.errors }, status: :unprocessable_content
  end

  def forgot_password
    return render json: { errors: { email: [ "can't be blank" ] } }, status: :unprocessable_content if forgot_password_params[:email].blank?

    raw, enc = Devise.token_generator.generate(User, :reset_password_token)

    if @user
      @user.verify_otp_token = enc
      @user.verify_otp_sent_at = Time.now.utc
      @user.save(validate: false)

      Rails.logger.debug "********************************"
      Rails.logger.debug "Otp Code: #{@user.otp_code}"
      Rails.logger.debug "********************************"
    end

    render json: { token: raw }
  end

  def verify_otp
    otp_code = verify_otp_params[:otp_code]

    if @user.authenticate_otp(otp_code, drift: 60)
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      @user.reset_password_token = enc
      @user.reset_password_sent_at = Time.now.utc
      @user.save(validate: false)

      return render json: { token: raw }
    end

    render json: { errors: { otp_code: [ "Invalid OTP" ] } }, status: :unprocessable_content
  end

  def reset_password
    if @user.reset_password(reset_password_params[:password], reset_password_params[:password_confirmation])
      @user.unlock_access!
      @user.send_password_change_notification

      return render json: {}
    end

    render json: { errors: @user.errors }, status: :unprocessable_content
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end

  def forgot_password_params
    params.require(:user).permit(:email)
  end

  def verify_otp_params
    params.require(:user).permit(:token, :otp_code)
  end

  def reset_password_params
    params.require(:user).permit(:token, :password, :password_confirmation)
  end

  def validate_verify_request
    render json: { errors: { token: [ "The verify request is invalid." ] } }, status: :unprocessable_content and return if @user.blank?

    return if @user.verify_otp_period_valid?

    render json: { errors: { token: [ "The verify request has expired" ] } }, status: :unprocessable_content
  end

  def validate_reset_request
    render json: { errors: { token: [ "The reset request is invalid." ] } }, status: :unprocessable_content and return if @user.blank?

    return if @user.reset_password_period_valid?

    render json: { errors: { token: [ "The reset request has expired" ] } }, status: :unprocessable_content
  end

  def find_user_by_verify_otp_token
    token = verify_otp_params[:token]
    return if token.blank?

    digested_token = Devise.token_generator.digest(User, :reset_password_token, token)
    @user = User.not_deleted.find_by(verify_otp_token: digested_token)
  end

  def find_user_by_reset_token
    token = reset_password_params[:token]
    return if token.blank?

    digested_token = Devise.token_generator.digest(User, :reset_password_token, token)
    @user = User.not_deleted.find_by(reset_password_token: digested_token)
  end

  def find_user_by_email
    email = forgot_password_params[:email]
    return if email.blank?

    @user = User.not_deleted.where("lower(email) = ?", email.strip.downcase).first
  end
end
