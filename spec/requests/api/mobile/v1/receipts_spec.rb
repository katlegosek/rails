# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::Receipts", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "GET /api/mobile/v1/receipts/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill, status: :processing) }
    let!(:processing_run) { create(:receipt_processing_run, receipt: receipt, provider: "fake_ocr", status: :processing) }

    it "returns receipt status and processing run while processing" do
      get "/api/mobile/v1/receipts/#{receipt.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt"]).to include("id" => receipt.id, "status" => "processing")
      expect(body["processing_run"]).to include("status" => "processing")
      expect(body).not_to have_key("receipt_items")
      expect(body).not_to have_key("receipt_adjustments")
    end

    it "returns items and adjustments when ready" do
      receipt.ready!
      create(:receipt_item, bill: bill, receipt: receipt, name: "Lamb Meatballs", position: 0)
      create(:receipt_adjustment, receipt: receipt, label: "VAT", kind: :tax, amount_cents: 100, position: 0)

      get "/api/mobile/v1/receipts/#{receipt.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt"]["status"]).to eq("ready")
      expect(body["receipt_items"].size).to eq(1)
      expect(body["receipt_adjustments"].size).to eq(1)
    end

    it "returns not found for another user's receipt" do
      other_receipt = create(:receipt, bill: create(:bill, user: create(:user)))

      get "/api/mobile/v1/receipts/#{other_receipt.id}"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Receipt not found")
    end
  end
end
