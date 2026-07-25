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

  describe "POST /api/mobile/v1/bills" do
    it "creates a draft bill for the current user" do
      post "/api/mobile/v1/bills", params: { bill: { title: "Friday dinner" } }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["bill"]).to include("title" => "Friday dinner", "status" => "draft")
      expect(user.bills.find(body["bill"]["id"])).to be_present
    end

    it "defaults the title when omitted" do
      post "/api/mobile/v1/bills", as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["bill"]["title"]).to eq("New bill")
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

  describe "bill room lifecycle" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill, status: :ready) }

    describe "POST /api/mobile/v1/bills/:id/confirm" do
      it "opens the room, confirms the receipt, and ensures a host and share token" do
        post "/api/mobile/v1/bills/#{bill.id}/confirm"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body.dig("bill", "session_status")).to eq("open")
        expect(body.dig("bill", "share_token")).to be_present
        expect(body["bill_participants"]).to contain_exactly(
          include("name" => user.full_name, "is_host" => true)
        )
        expect(bill.reload).to have_attributes(status: "active", confirmed_at: be_present)
        expect(receipt.reload).to be_confirmed
      end

      it "is idempotent and preserves the share token and host" do
        post "/api/mobile/v1/bills/#{bill.id}/confirm"
        token = bill.reload.share_token

        post "/api/mobile/v1/bills/#{bill.id}/confirm"

        expect(response).to have_http_status(:ok)
        expect(bill.reload.share_token).to eq(token)
        expect(bill.bill_participants.where(is_host: true).count).to eq(1)
      end

      it "does not open another user's bill" do
        other_bill = create(:bill, user: create(:user))
        create(:receipt, bill: other_bill, status: :ready)

        post "/api/mobile/v1/bills/#{other_bill.id}/confirm"

        expect(response).to have_http_status(:not_found)
        expect(other_bill.reload).to be_session_draft
      end
    end

    describe "GET /api/mobile/v1/bills/:id/room" do
      it "returns share and breakdown data" do
        bill.update!(share_token: "room-token", session_status: :open)
        item = create(:receipt_item, bill: bill, receipt: receipt)
        participant = create(:bill_participant, bill: bill)
        create(:item_assignment, receipt_item: item, bill_participant: participant)

        get "/api/mobile/v1/bills/#{bill.id}/room"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(
          "bill",
          "receipt",
          "receipt_items",
          "receipt_adjustments",
          "bill_participants",
          "item_assignments"
        )
        expect(response.parsed_body.dig("bill", "share_token")).to eq("room-token")
      end
    end

    describe "POST /api/mobile/v1/bills/:id/finalize" do
      it "finalizes the current user's bill" do
        bill.update!(session_status: :open, status: :active)

        post "/api/mobile/v1/bills/#{bill.id}/finalize"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("bill", "session_status")).to eq("finalized")
        expect(bill.reload).to have_attributes(status: "completed", finalized_at: be_present)
      end

      it "does not finalize another user's bill" do
        other_bill = create(:bill, user: create(:user), status: :active)

        post "/api/mobile/v1/bills/#{other_bill.id}/finalize"

        expect(response).to have_http_status(:not_found)
        expect(other_bill.reload).not_to be_session_finalized
      end
    end
  end
end
