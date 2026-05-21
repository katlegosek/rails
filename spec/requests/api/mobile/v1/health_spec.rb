# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/mobile/v1/health", type: :request do
  it "returns ok JSON" do
    get "/api/mobile/v1/health"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "status" => "ok",
      "app" => "bill-splitting-api"
    )
  end
end
