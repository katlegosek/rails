# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile API error responses", type: :request do
  describe "validation_error (422)" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }

    it "returns a structured validation payload" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: { kind: "tax", amount_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)

      error = api_error(response.parsed_body)
      expect(error["code"]).to eq("validation_error")
      expect(error["message"]).to eq("Could not save record.")
      expect(error["details"]["label"]).to include("can't be blank")
    end
  end

  describe "not_found (404)" do
    it "returns a structured not found payload" do
      get "/api/mobile/v1/bills/0"

      expect(response).to have_http_status(:not_found)

      error = api_error(response.parsed_body)
      expect(error["code"]).to eq("not_found")
      expect(error["message"]).to eq("Bill not found")
      expect(error).not_to have_key("details")
    end
  end

  describe "bad_request (400)" do
    let(:bill) { create(:bill, user: user) }

    it "returns a structured bad request payload for a missing upload" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_images"

      expect(response).to have_http_status(:bad_request)

      error = api_error(response.parsed_body)
      expect(error["code"]).to eq("bad_request")
      expect(error["message"]).to eq("Image is required.")
      expect(error["details"]["image"]).to include("can't be blank")
    end

    it "returns a structured bad request payload for a missing param" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {}, as: :json

      expect(response).to have_http_status(:bad_request)

      error = api_error(response.parsed_body)
      expect(error["code"]).to eq("bad_request")
      expect(error["details"]["parameter"]).to include("receipt_item")
    end
  end
end
