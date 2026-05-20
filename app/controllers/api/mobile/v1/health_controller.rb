# frozen_string_literal: true

class Api::Mobile::V1::HealthController < Api::Mobile::V1::BaseController
  def show
    render json: { status: "ok", app: "bill-splitting-api" }
  end
end
