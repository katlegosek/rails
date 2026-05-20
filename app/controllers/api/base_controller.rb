# frozen_string_literal: true

class Api::BaseController < ApplicationController
  respond_to :json

  before_action :doorkeeper_authorize!

  skip_forgery_protection

  def destroy(object)
    ActiveRecord::Base.transaction do
      render json: {}, status: :no_content if object.destroy
    rescue StandardError => e
      render json: { errors: e }, status: :unprocessable_content
    end
  end

  def archive(object)
    ActiveRecord::Base.transaction do
      render json: {}, status: :no_content if object.archive
    rescue StandardError => e
      render json: { errors: e }, status: :unprocessable_content
    end
  end

  def restore(object)
    ActiveRecord::Base.transaction do
      render json: {}, status: :no_content if object.restore
    rescue StandardError => e
      render json: { errors: e }, status: :unprocessable_content
    end
  end

  protected

  def current_user
    @current_user ||= User.find(doorkeeper_token[:resource_owner_id]) if doorkeeper_token
  end
end
