# frozen_string_literal: true

class Api::Mobile::V1::HealthController < Api::Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!

  def show
    render json: { status: "ok", app: "bill-splitting-api" }
  end
end
