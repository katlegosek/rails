# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Receipt items API", type: :request do
  describe "POST /api/mobile/v1/bills/:bill_id/receipt_items" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }

    it "creates a receipt item" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: { name: "Burrata", unit_price_cents: 9_500, quantity: 2 }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["receipt_item"]).to include(
        "name" => "Burrata",
        "total_cents" => 19_000,
        "receipt_id" => receipt.id
      )
      expect(body["bill_summary"]).to be_present
    end

    it "returns validation_error when name is missing" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: { unit_price_cents: 1_000 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/receipt_items", params: {
        receipt_item: { name: "Stolen", unit_price_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end
  end

  describe "PATCH /api/mobile/v1/receipt_items/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_500, total_cents: 9_500) }

    it "updates a receipt item" do
      patch "/api/mobile/v1/receipt_items/#{item.id}", params: {
        receipt_item: { quantity: 2 }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["receipt_item"]).to include("quantity" => 2.0, "total_cents" => 19_000)
      expect(response.parsed_body["bill_summary"]).to be_present
    end

    it "returns validation_error when name is blank" do
      patch "/api/mobile/v1/receipt_items/#{item.id}", params: {
        receipt_item: { name: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's item" do
      other_item = create(:receipt_item, bill: create(:bill, user: create(:user)))

      patch "/api/mobile/v1/receipt_items/#{other_item.id}", params: {
        receipt_item: { name: "Hacker" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end
  end
end
