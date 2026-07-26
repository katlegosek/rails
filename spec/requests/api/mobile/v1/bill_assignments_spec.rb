# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bill assignments API", type: :request do
  describe "POST /api/mobile/v1/bills/:id/split_unassigned_equally" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:katlego) { create(:bill_participant, bill: bill) }
    let!(:sam) { create(:bill_participant, bill: bill) }
    let!(:assigned_item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 9_000, position: 0) }
    let!(:unassigned_item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 6_000, position: 1) }

    before do
      create(:item_assignment, receipt_item: assigned_item, bill_participant: katlego, amount_cents: 9_000, split_method: :custom)
    end

    it "assigns only unassigned items" do
      post "/api/mobile/v1/bills/#{bill.id}/split_unassigned_equally"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["bill_summary"]["bill"]["assigned_items_count"]).to eq(2)
      expect(assigned_item.reload.item_assignments.count).to eq(1)
      expect(unassigned_item.reload.item_assignments.count).to eq(2)
    end

    it "returns validation_error when there are no participants" do
      empty_bill = create(:bill, user: user)
      receipt = create(:receipt, bill: empty_bill)
      create(:receipt_item, bill: empty_bill, receipt: receipt, total_cents: 1_000)

      post "/api/mobile/v1/bills/#{empty_bill.id}/split_unassigned_equally"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/split_unassigned_equally"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not split assignments after finalization" do
      bill.update!(session_status: :finalized)

      post "/api/mobile/v1/bills/#{bill.id}/split_unassigned_equally"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(unassigned_item.item_assignments).to be_empty
    end
  end

  describe "POST /api/mobile/v1/bills/:id/split_all_equally" do
    it "returns validation_error when there are no participants" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      create(:receipt_item, bill: bill, receipt: receipt, total_cents: 1_000)

      post "/api/mobile/v1/bills/#{bill.id}/split_all_equally"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end
  end

  describe "DELETE /api/mobile/v1/bills/:id/assignments" do
    it "succeeds when the bill has no participants" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      create(:receipt_item, bill: bill, receipt: receipt, total_cents: 2_000)

      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("bill_summary")
    end

    it "succeeds when the bill has no receipt items" do
      bill = create(:bill, user: user)
      create(:receipt, bill: bill)
      create(:bill_participant, bill: bill)

      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("bill_summary")
    end

    it "succeeds when there are no assignments" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      create(:receipt_item, bill: bill, receipt: receipt, total_cents: 1_000)
      create(:bill_participant, bill: bill)

      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("bill_summary")
    end

    it "clears existing assignments" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      item = create(:receipt_item, bill: bill, receipt: receipt, total_cents: 3_000)
      participant = create(:bill_participant, bill: bill)
      create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 3_000)

      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:ok)
      expect(item.reload.item_assignments).to be_empty
      expect(response.parsed_body["bill_summary"]["bill"]["assigned_items_count"]).to eq(0)
    end

    it "returns not_found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      delete "/api/mobile/v1/bills/#{other_bill.id}/assignments"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not clear assignments after finalization" do
      bill = create(:bill, user: user, session_status: :finalized)
      receipt = create(:receipt, bill: bill)
      item = create(:receipt_item, bill: bill, receipt: receipt, total_cents: 3_000)
      participant = create(:bill_participant, bill: bill)
      assignment = create(
        :item_assignment,
        receipt_item: item,
        bill_participant: participant,
        amount_cents: 3_000
      )

      delete "/api/mobile/v1/bills/#{bill.id}/assignments"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(ItemAssignment.exists?(assignment.id)).to be(true)
    end
  end
end
