# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::Health", type: :request do
  describe "GET /api/mobile/v1/health" do
    it "returns ok status" do
      get "/api/mobile/v1/health"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "status" => "ok",
        "app" => "bill-splitting-api"
      )
    end
  end
end
