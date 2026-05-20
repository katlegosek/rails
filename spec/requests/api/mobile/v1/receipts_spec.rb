# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Receipts API", type: :request do
  describe "GET /api/mobile/v1/receipts/:id" do
    let(:bill) { create(:bill, user: user) }

    it "returns processing status without items while processing" do
      receipt = create(:receipt, bill: bill, status: :processing)
      create(:receipt_processing_run, receipt: receipt, provider: "fake_ocr", status: :processing)

      get "/api/mobile/v1/receipts/#{receipt.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["receipt"]).to include("status" => "processing")
      expect(body["processing_run"]).to include("status" => "processing")
      expect(body).not_to have_key("receipt_items")
    end

    it "returns items and adjustments when ready" do
      receipt = create(:receipt, bill: bill, status: :ready)
      create(:receipt_item, bill: bill, receipt: receipt, name: "Lamb Meatballs")
      create(:receipt_adjustment, receipt: receipt, label: "VAT", kind: :tax, amount_cents: 100)

      get "/api/mobile/v1/receipts/#{receipt.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["receipt"]["status"]).to eq("ready")
      expect(body["receipt_items"].size).to eq(1)
      expect(body["receipt_adjustments"].size).to eq(1)
    end

    it "returns not_found for another user's receipt" do
      other_receipt = create(:receipt, bill: create(:bill, user: create(:user)))

      get "/api/mobile/v1/receipts/#{other_receipt.id}"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end
  end
end
