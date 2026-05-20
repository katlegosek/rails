# frozen_string_literal: true

class Api::Mobile::V1::BaseController < ApplicationController
  respond_to :json

  skip_forgery_protection

  private

  def current_user
    @current_user ||= User.first
  end

  def render_not_found(message = "Bill not found")
    render json: { error: message }, status: :not_found
  end
end
