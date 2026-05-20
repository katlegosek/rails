# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bills API", type: :request do
  describe "GET /api/mobile/v1/bills" do
    it "returns bills for the current user" do
      bill = create(:bill, user: user, status: :active)
      create(:bill_participant, bill: bill)

      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["bills"].size).to eq(1)
      expect(response.parsed_body["bills"].first).to include("id" => bill.id, "status" => "active")
    end

    it "does not include other users' bills" do
      create(:bill, user: create(:user))

      get "/api/mobile/v1/bills"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["bills"]).to eq([])
    end
  end

  describe "GET /api/mobile/v1/bills/:id" do
    it "returns the bill payload" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      create(:receipt_item, bill: bill, receipt: receipt)

      get "/api/mobile/v1/bills/#{bill.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["bill"]["id"]).to eq(bill.id)
      expect(body["receipt"]["id"]).to eq(receipt.id)
      expect(body["receipt_items"]).to be_an(Array)
      expect(body["bill_participants"]).to be_an(Array)
    end

    it "returns not_found when the bill does not belong to the current user" do
      other_bill = create(:bill, user: create(:user))

      get "/api/mobile/v1/bills/#{other_bill.id}"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Bill not found")
    end
  end

  describe "GET /api/mobile/v1/bills/:id/summary" do
    it "returns the summary payload" do
      bill = create(:bill, user: user)
      receipt = create(:receipt, bill: bill)
      item = create(:receipt_item, bill: bill, receipt: receipt, total_cents: 5_000)
      participant = create(:bill_participant, bill: bill)
      create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 5_000)

      get "/api/mobile/v1/bills/#{bill.id}/summary"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include("bill", "totals", "participants", "receipt_adjustments")
      expect(body["bill"]["id"]).to eq(bill.id)
      expect(body["totals"]["bill_total_cents"]).to eq(5_000)
    end

    it "returns not_found when the bill does not exist" do
      get "/api/mobile/v1/bills/0/summary"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end
  end
end
