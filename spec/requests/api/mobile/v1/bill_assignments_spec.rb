# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::BillAssignments", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "POST /api/mobile/v1/bills/:id/split_all_equally" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:katlego) { create(:bill_participant, bill: bill, name: "Katlego") }
    let!(:sam) { create(:bill_participant, bill: bill, name: "Sam") }
    let!(:burrata) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 9_000, position: 0) }
    let!(:wine) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 20_000, position: 1) }

    it "assigns every receipt item equally to all participants" do
      post "/api/mobile/v1/bills/#{bill.id}/split_all_equally"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["bill_summary"]["bill"]["items_count"]).to eq(2)
      expect(body["bill_summary"]["bill"]["assigned_items_count"]).to eq(2)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(29_000)
      expect(burrata.reload.item_assignments.count).to eq(2)
      expect(burrata.item_assignments.sum(:amount_cents)).to eq(9_000)
    end

    it "returns validation errors when the bill has no participants" do
      empty_bill = create(:bill, user: user)
      create(:receipt_item, bill: empty_bill, receipt: create(:receipt, bill: empty_bill), total_cents: 1_000, position: 0)

      post "/api/mobile/v1/bills/#{empty_bill.id}/split_all_equally"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(api_error(response.parsed_body)["details"]["participants"]).to include("must have at least one participant")
    end

    it "returns validation errors when the bill has no receipt items" do
      empty_bill = create(:bill, user: user)
      create(:bill_participant, bill: empty_bill)

      post "/api/mobile/v1/bills/#{empty_bill.id}/split_all_equally"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["details"]["receipt_items"]).to include("must have at least one receipt item")
    end
  end

  describe "POST /api/mobile/v1/bills/:id/split_unassigned_equally" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:katlego) { create(:bill_participant, bill: bill, name: "Katlego") }
    let!(:sam) { create(:bill_participant, bill: bill, name: "Sam") }
    let!(:assigned_item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 9_000, position: 0) }
    let!(:unassigned_item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 6_000, position: 1) }

    before do
      create(:item_assignment, receipt_item: assigned_item, bill_participant: katlego, amount_cents: 9_000, split_method: :custom)
    end

    it "assigns only receipt items without assignments" do
      post "/api/mobile/v1/bills/#{bill.id}/split_unassigned_equally"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(assigned_item.reload.item_assignments.count).to eq(1)
      expect(unassigned_item.reload.item_assignments.count).to eq(2)
      expect(unassigned_item.item_assignments.sum(:amount_cents)).to eq(6_000)
      expect(body["bill_summary"]["bill"]["assigned_items_count"]).to eq(2)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(15_000)
    end
  end

  describe "DELETE /api/mobile/v1/bills/:id/assignments" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:participant) { create(:bill_participant, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 9_500, position: 0) }

    before do
      create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 9_500, split_method: :equal)
    end

    it "clears all assignments for the bill" do
      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(item.reload.item_assignments).to be_empty
      expect(body["bill_summary"]["bill"]["assigned_items_count"]).to eq(0)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(0)
    end

    it "returns not found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      delete "/api/mobile/v1/bills/#{other_bill.id}/assignments"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Bill not found")
    end
  end
end
