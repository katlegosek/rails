# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Item assignments API", type: :request do
  describe "PUT /api/mobile/v1/receipt_items/:receipt_item_id/assignments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 10_000) }
    let!(:katlego) { create(:bill_participant, bill: bill, name: "Katlego") }
    let!(:sam) { create(:bill_participant, bill: bill, name: "Sam") }

    it "replaces assignments equally" do
      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [ katlego.id, sam.id ],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["receipt_item"]["id"]).to eq(item.id)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(10_000)
    end

    it "returns validation_error for unsupported split_method" do
      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [ katlego.id ],
        split_method: "custom"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(api_error(response.parsed_body)["details"]["split_method"]).to be_present
    end

    it "returns not_found for another user's receipt item" do
      other_item = create(:receipt_item, bill: create(:bill, user: create(:user)))

      put "/api/mobile/v1/receipt_items/#{other_item.id}/assignments", params: {
        participant_ids: [ katlego.id ],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not replace assignments after finalization" do
      bill.update!(session_status: :finalized)

      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [ katlego.id ],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(item.item_assignments).to be_empty
    end
  end
end
