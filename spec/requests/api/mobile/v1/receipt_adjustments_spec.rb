# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Receipt adjustments API", type: :request do
  describe "POST /api/mobile/v1/receipts/:receipt_id/adjustments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }

    it "creates an adjustment" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: { label: "VAT (15%)", kind: "tax", amount_cents: 1_425 }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["receipt_adjustment"]).to include(
        "receipt_id" => receipt.id,
        "kind" => "tax",
        "affects_total" => false
      )
      expect(body["bill_summary"]["receipt_adjustments"].size).to eq(1)
    end

    it "returns validation_error when label is missing" do
      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: { kind: "tax", amount_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's receipt" do
      other_receipt = create(:receipt, bill: create(:bill, user: create(:user)))

      post "/api/mobile/v1/receipts/#{other_receipt.id}/adjustments", params: {
        receipt_adjustment: { label: "Tax", kind: "tax", amount_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not create adjustments after finalization" do
      bill.update!(session_status: :finalized)

      post "/api/mobile/v1/receipts/#{receipt.id}/adjustments", params: {
        receipt_adjustment: { label: "Tip", kind: "tip", amount_cents: 500 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(receipt.receipt_adjustments).to be_empty
    end
  end
end
