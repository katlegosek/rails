# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::ReceiptAdjustments", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "POST /api/mobile/v1/receipts/:receipt_id/adjustments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }

    it "creates an adjustment with defaults and returns bill summary" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: {
          label: "Delivery",
          kind: "delivery_fee",
          amount_cents: 500
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body

      expect(body["receipt_adjustment"]).to include(
        "receipt_id" => receipt.id,
        "label" => "Delivery",
        "kind" => "delivery_fee",
        "amount_cents" => 500,
        "included_in_total" => false,
        "position" => 0
      )
      expect(body["bill_summary"]["receipt_adjustments"].size).to eq(1)
    end

    it "allows negative amount_cents for discounts" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: {
          label: "Discount",
          kind: "discount",
          amount_cents: -250,
          included_in_total: true
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["receipt_adjustment"]).to include(
        "amount_cents" => -250,
        "included_in_total" => true
      )
    end

    it "returns validation errors when label is missing" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: { kind: "tax", amount_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "returns not found for another user's receipt" do
      other_receipt = create(:receipt, bill: create(:bill, user: create(:user)))

      post "/api/mobile/v1/receipts/#{other_receipt.id}/adjustments", params: {
        receipt_adjustment: { label: "Tax", kind: "tax", amount_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Receipt not found")
    end
  end

  describe "PATCH /api/mobile/v1/receipt_adjustments/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:adjustment) do
      create(:receipt_adjustment, receipt: receipt, label: "VAT", kind: :tax, amount_cents: 1_425, position: 0)
    end

    it "updates an adjustment and returns bill summary" do
      patch "/api/mobile/v1/receipt_adjustments/#{adjustment.id}", params: {
        receipt_adjustment: { label: "VAT (15%)", amount_cents: 1_500, included_in_total: true }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt_adjustment"]).to include(
        "id" => adjustment.id,
        "label" => "VAT (15%)",
        "amount_cents" => 1_500,
        "included_in_total" => true
      )
      expect(body["bill_summary"]["receipt_adjustments"].first).to include("amount_cents" => 1_500)
    end

    it "returns not found for another user's adjustment" do
      other_adjustment = create(:receipt_adjustment, receipt: create(:receipt, bill: create(:bill, user: create(:user))))

      patch "/api/mobile/v1/receipt_adjustments/#{other_adjustment.id}", params: {
        receipt_adjustment: { label: "Hacker" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Receipt adjustment not found")
    end
  end

  describe "DELETE /api/mobile/v1/receipt_adjustments/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:adjustment) do
      create(:receipt_adjustment, receipt: receipt, label: "Tip", kind: :tip, amount_cents: 500, position: 0)
    end

    it "deletes the adjustment and returns bill summary" do
      delete "/api/mobile/v1/receipt_adjustments/#{adjustment.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt_adjustment"]).to include("id" => adjustment.id, "label" => "Tip")
      expect(ReceiptAdjustment.exists?(adjustment.id)).to be(false)
      expect(body["bill_summary"]["receipt_adjustments"]).to eq([])
    end
  end
end
