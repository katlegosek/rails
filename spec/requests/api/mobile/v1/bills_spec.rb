# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::Bills", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "GET /api/mobile/v1/bills" do
    it "returns an empty list when the user has no bills" do
      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("bills" => [])
    end

    it "returns bill summaries for the current user" do
      bill = create(:bill, user: user, status: :active)
      receipt = create(:receipt, bill: bill, status: :confirmed)
      create(:bill_participant, bill: bill, name: "Katlego")
      create(:bill_participant, bill: bill, name: "Sam")
      create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_500, total_cents: 9_500, position: 0)
      create(:receipt_adjustment, receipt: receipt, label: "VAT (15%)", kind: :tax, amount_cents: 1_425, position: 1)
      create(
        :receipt_processing_run,
        receipt: receipt,
        status: :completed,
        raw_ai_response: { title: "Observatory Small Plates", merchant: "Observatory Restaurant" }
      )

      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["bills"].size).to eq(1)

      summary = body["bills"].first
      expect(summary).to include(
        "id" => bill.id,
        "title" => "Observatory Small Plates",
        "status" => "active",
        "total_cents" => 10_925,
        "participants_count" => 2,
        "receipt_name" => "Observatory Restaurant"
      )
      expect(summary["receipt_date"]).to be_present
      expect(summary["created_at"]).to be_present
    end

    it "does not return bills belonging to other users" do
      other_user = create(:user)
      create(:bill, user: other_user)

      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["bills"]).to eq([])
    end
  end

  describe "GET /api/mobile/v1/bills/:id" do
    it "returns the full bill payload" do
      bill = create(:bill, user: user, status: :active)
      receipt = create(:receipt, bill: bill, status: :confirmed)
      participant = create(:bill_participant, bill: bill, name: "Katlego", is_host: true, seat_index: 0)
      item = create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_500, total_cents: 9_500, position: 0)
      adjustment = create(:receipt_adjustment, receipt: receipt, label: "Subtotal", kind: :subtotal, amount_cents: 9_500, position: 0)
      assignment = create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 9_500, split_method: :custom)
      create(
        :receipt_processing_run,
        receipt: receipt,
        status: :completed,
        raw_ai_response: { title: "Friday Night Out", merchant: "The Local Grill" }
      )

      get "/api/mobile/v1/bills/#{bill.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["bill"]).to include(
        "id" => bill.id,
        "title" => "Friday Night Out",
        "status" => "active",
        "total_cents" => 19_000,
        "receipt_name" => "The Local Grill"
      )
      expect(body["receipt"]).to include("id" => receipt.id, "status" => "confirmed")
      expect(body["receipt_items"].size).to eq(1)
      expect(body["receipt_items"].first).to include("name" => "Burrata", "total_cents" => 9_500)
      expect(body["receipt_adjustments"].size).to eq(1)
      expect(body["receipt_adjustments"].first).to include("id" => adjustment.id, "kind" => "subtotal")
      expect(body["bill_participants"].size).to eq(1)
      expect(body["bill_participants"].first).to include("name" => "Katlego", "is_host" => true)
      expect(body["item_assignments"].size).to eq(1)
      expect(body["item_assignments"].first).to include(
        "id" => assignment.id,
        "receipt_item_id" => item.id,
        "bill_participant_id" => participant.id,
        "amount_cents" => 9_500,
        "split_method" => "custom"
      )
    end

    it "returns consistent error JSON when the bill is not found" do
      get "/api/mobile/v1/bills/0"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Bill not found")
    end

    it "returns not found when the bill belongs to another user" do
      other_bill = create(:bill, user: create(:user))

      get "/api/mobile/v1/bills/#{other_bill.id}"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Bill not found")
    end
  end
end
