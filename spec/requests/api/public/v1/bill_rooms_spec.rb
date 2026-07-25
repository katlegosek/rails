# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public bill rooms API", type: :request do
  let(:bill) do
    create(
      :bill,
      session_status: :open,
      status: :active,
      share_token: "public-room-token"
    )
  end
  let!(:receipt) { create(:receipt, bill: bill, status: :confirmed, total_cents: 2_500) }
  let!(:first_item) do
    create(:receipt_item, bill: bill, receipt: receipt, name: "Pizza", total_cents: 2_000)
  end
  let!(:second_item) do
    create(:receipt_item, bill: bill, receipt: receipt, name: "Water", total_cents: 500)
  end
  let!(:host) { create(:bill_participant, bill: bill, name: "Host", is_host: true, seat_index: 0) }

  describe "GET /api/public/v1/bill_rooms/:share_token" do
    it "returns an open room without requiring mobile authentication" do
      get "/api/public/v1/bill_rooms/#{bill.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("bill", "title")).to eq(bill.display_title)
      expect(response.parsed_body["receipt_items"].pluck("name")).to contain_exactly("Pizza", "Water")
      expect(response.parsed_body["current_participant_id"]).to be_nil
    end

    it "returns not_found for a draft or unknown room" do
      bill.update!(session_status: :draft)

      get "/api/public/v1/bill_rooms/#{bill.share_token}"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    end
  end

  describe "POST /api/public/v1/bill_rooms/:share_token/join" do
    it "creates a guest participant and returns the raw token only once" do
      post "/api/public/v1/bill_rooms/#{bill.share_token}/join",
        params: { guest: { name: "  Neo M  " } },
        as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      participant = bill.bill_participants.find(body["current_participant_id"])
      expect(participant).to have_attributes(name: "Neo M", joined_at: be_present)
      expect(body["guest_token"]).to be_present
      expect(participant.guest_token_digest).to eq(
        BillParticipant.digest_guest_token(body["guest_token"])
      )
      expect(response.body).not_to include(participant.guest_token_digest)
    end

    it "rejects a blank guest name" do
      post "/api/public/v1/bill_rooms/#{bill.share_token}/join",
        params: { guest: { name: " " } },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_error")
    end

    it "does not allow joining a finalized room" do
      bill.update!(session_status: :finalized)

      post "/api/public/v1/bill_rooms/#{bill.share_token}/join",
        params: { guest: { name: "Late guest" } },
        as: :json

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("room_closed")
    end

    it "reuses an existing valid guest session instead of creating a duplicate" do
      participant = create(:bill_participant, bill: bill, name: "Neo", joined_at: Time.current)
      guest_token = participant.issue_guest_token!

      expect {
        post "/api/public/v1/bill_rooms/#{bill.share_token}/join",
          params: { guest: { name: "Duplicate Neo" } },
          headers: { "Authorization" => "Bearer #{guest_token}" },
          as: :json
      }.not_to change { bill.bill_participants.count }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["current_participant_id"]).to eq(participant.id)
      expect(response.parsed_body).not_to have_key("guest_token")
      expect(participant.reload.name).to eq("Neo")
    end

    it "rejects an invalid existing guest session instead of creating a duplicate" do
      expect {
        post "/api/public/v1/bill_rooms/#{bill.share_token}/join",
          params: { guest: { name: "Neo" } },
          headers: { "Authorization" => "Bearer invalid" },
          as: :json
      }.not_to change { bill.bill_participants.count }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end
  end

  describe "guest session management" do
    let(:participant) { create(:bill_participant, bill: bill, name: "Neo", joined_at: Time.current) }
    let(:guest_token) { participant.issue_guest_token! }
    let(:headers) { { "Authorization" => "Bearer #{guest_token}" } }

    it "renames the authenticated guest" do
      patch "/api/public/v1/bill_rooms/#{bill.share_token}/guest",
        params: { guest: { name: "  Neo M  " } },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(participant.reload).to have_attributes(name: "Neo M", initials: "NM")
      expect(response.parsed_body["current_participant_id"]).to eq(participant.id)
    end

    it "does not rename a guest with a token from another room" do
      other_bill = create(:bill, session_status: :open, share_token: "other-room")
      other_participant = create(:bill_participant, bill: other_bill, joined_at: Time.current)
      other_token = other_participant.issue_guest_token!

      patch "/api/public/v1/bill_rooms/#{bill.share_token}/guest",
        params: { guest: { name: "Intruder" } },
        headers: { "Authorization" => "Bearer #{other_token}" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(other_participant.reload.name).not_to eq("Intruder")
    end

    it "leaves the room and rebalances or clears every affected claim" do
      create(
        :item_assignment,
        receipt_item: first_item,
        bill_participant: host,
        amount_cents: 1_000
      )
      create(
        :item_assignment,
        receipt_item: first_item,
        bill_participant: participant,
        amount_cents: 1_000
      )
      create(
        :item_assignment,
        receipt_item: second_item,
        bill_participant: participant,
        amount_cents: 500
      )

      delete "/api/public/v1/bill_rooms/#{bill.share_token}/guest", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["current_participant_id"]).to be_nil
      expect(BillParticipant.exists?(participant.id)).to be(false)
      expect(first_item.item_assignments.reload.sole).to have_attributes(
        bill_participant_id: host.id,
        amount_cents: first_item.total_cents
      )
      expect(second_item.item_assignments.reload).to be_empty

      get "/api/public/v1/bill_rooms/#{bill.share_token}", headers: headers
      expect(response.parsed_body["current_participant_id"]).to be_nil
    end

    it "keeps guest identity and claims immutable after finalization" do
      create(
        :item_assignment,
        receipt_item: first_item,
        bill_participant: participant,
        amount_cents: first_item.total_cents
      )
      bill.update!(session_status: :finalized)

      patch "/api/public/v1/bill_rooms/#{bill.share_token}/guest",
        params: { guest: { name: "Changed" } },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:conflict)
      expect(participant.reload.name).to eq("Neo")

      delete "/api/public/v1/bill_rooms/#{bill.share_token}/guest", headers: headers

      expect(response).to have_http_status(:conflict)
      expect(BillParticipant.exists?(participant.id)).to be(true)
      expect(first_item.item_assignments.reload.sole.bill_participant_id).to eq(participant.id)
    end
  end

  describe "guest item claims" do
    let(:participant) { create(:bill_participant, bill: bill, name: "Neo", joined_at: Time.current) }
    let(:guest_token) { participant.issue_guest_token! }
    let(:headers) { { "Authorization" => "Bearer #{guest_token}" } }

    it "claims an item and restores the guest identity on room refresh" do
      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{first_item.id}/claim",
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(first_item.item_assignments.reload.sole.bill_participant).to eq(participant)
      expect(first_item.item_assignments.sole.amount_cents).to eq(first_item.total_cents)

      get "/api/public/v1/bill_rooms/#{bill.share_token}", headers: headers

      expect(response.parsed_body["current_participant_id"]).to eq(participant.id)
    end

    it "shares an already-claimed item equally and can unclaim it" do
      create(
        :item_assignment,
        receipt_item: first_item,
        bill_participant: host,
        amount_cents: first_item.total_cents
      )

      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{first_item.id}/claim",
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(first_item.item_assignments.reload.pluck(:amount_cents)).to contain_exactly(1_000, 1_000)

      delete "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{first_item.id}/claim",
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(first_item.item_assignments.reload.sole).to have_attributes(
        bill_participant_id: host.id,
        amount_cents: first_item.total_cents
      )
    end

    it "rejects a missing or invalid guest token" do
      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{first_item.id}/claim"

      expect(response).to have_http_status(:unauthorized)

      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{first_item.id}/claim",
        headers: { "Authorization" => "Bearer invalid" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "cannot claim an item belonging to another bill" do
      other_bill = create(:bill)
      other_receipt = create(:receipt, bill: other_bill)
      other_item = create(:receipt_item, bill: other_bill, receipt: other_receipt)

      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{other_item.id}/claim",
        headers: headers

      expect(response).to have_http_status(:not_found)
      expect(other_item.item_assignments).to be_empty
    end

    it "rejects claims after finalization" do
      bill.update!(session_status: :finalized)

      post "/api/public/v1/bill_rooms/#{bill.share_token}/items/#{second_item.id}/claim",
        headers: headers

      expect(response).to have_http_status(:conflict)
      expect(second_item.item_assignments).to be_empty
    end
  end
end
