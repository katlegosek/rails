# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::ItemAssignments", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "PUT /api/mobile/v1/receipt_items/:receipt_item_id/assignments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 10_000, position: 0) }
    let!(:katlego) { create(:bill_participant, bill: bill, name: "Katlego") }
    let!(:sam) { create(:bill_participant, bill: bill, name: "Sam") }

    it "replaces assignments and returns receipt item with bill summary" do
      other_participant = create(:bill_participant, bill: bill, name: "Alex")
      old_assignment = create(:item_assignment, receipt_item: item, bill_participant: other_participant, amount_cents: 10_000, split_method: :equal)

      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [ katlego.id, sam.id ],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(ItemAssignment.exists?(old_assignment.id)).to be(false)
      expect(body["receipt_item"]["id"]).to eq(item.id)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(10_000)
      expect(body["bill_summary"]["participants"].find { |p| p["id"] == katlego.id }["amount_due_cents"]).to eq(5_000)
      expect(body["bill_summary"]["participants"].find { |p| p["id"] == sam.id }["amount_due_cents"]).to eq(5_000)
    end

    it "clears assignments when participant_ids is empty" do
      create(:item_assignment, receipt_item: item, bill_participant: katlego, amount_cents: 10_000, split_method: :equal)

      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(item.reload.item_assignments).to be_empty
      expect(response.parsed_body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(0)
    end

    it "returns validation errors for unsupported split_method" do
      put "/api/mobile/v1/receipt_items/#{item.id}/assignments", params: {
        participant_ids: [ katlego.id ],
        split_method: "custom"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["split_method"]).to include("must be equal")
    end

    it "returns not found for another user's receipt item" do
      other_item = create(:receipt_item, bill: create(:bill, user: create(:user)))

      put "/api/mobile/v1/receipt_items/#{other_item.id}/assignments", params: {
        participant_ids: [ katlego.id ],
        split_method: "equal"
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Receipt item not found")
    end
  end

  describe "DELETE /api/mobile/v1/receipt_items/:receipt_item_id/assignments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 9_500, position: 0) }
    let!(:participant) { create(:bill_participant, bill: bill, name: "Katlego") }
    let!(:assignment) { create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 9_500, split_method: :equal) }

    it "clears assignments and returns receipt item with bill summary" do
      delete "/api/mobile/v1/receipt_items/#{item.id}/assignments"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(ItemAssignment.exists?(assignment.id)).to be(false)
      expect(body["receipt_item"]["id"]).to eq(item.id)
      expect(body["bill_summary"]["bill"]["assigned_items_count"]).to eq(0)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(0)
    end
  end
end
