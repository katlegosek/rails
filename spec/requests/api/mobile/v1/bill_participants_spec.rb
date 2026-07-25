# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bill participants API", type: :request do
  describe "POST /api/mobile/v1/bills/:bill_id/participants" do
    let(:bill) { create(:bill, user: user) }

    it "creates a participant" do
      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: { name: "Sam", initials: "S", seat_index: 1 }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["participant"]).to include("bill_id" => bill.id, "name" => "Sam")
      expect(body["bill_summary"]["participants"].size).to eq(1)
    end

    it "returns validation_error when name is missing" do
      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: { name: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/participants", params: {
        participant: { name: "Sam" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not add participants after finalization" do
      bill.update!(session_status: :finalized)

      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: { name: "Sam" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(bill.bill_participants).to be_empty
    end
  end

  describe "PATCH /api/mobile/v1/bill_participants/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:participant) { create(:bill_participant, bill: bill, name: "Sam") }

    it "updates a participant" do
      patch "/api/mobile/v1/bill_participants/#{participant.id}", params: {
        participant: { name: "Samuel", settled: true }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["participant"]).to include("name" => "Samuel", "settled" => true)
      expect(response.parsed_body["bill_summary"]).to be_present
    end

    it "returns validation_error when name is blank" do
      patch "/api/mobile/v1/bill_participants/#{participant.id}", params: {
        participant: { name: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
    end

    it "returns not_found for another user's participant" do
      other = create(:bill_participant, bill: create(:bill, user: create(:user)))

      patch "/api/mobile/v1/bill_participants/#{other.id}", params: {
        participant: { name: "Hacker" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)["code"]).to eq("not_found")
    end

    it "does not update participants after finalization" do
      bill.update!(session_status: :finalized)

      patch "/api/mobile/v1/bill_participants/#{participant.id}", params: {
        participant: { name: "Samuel" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(participant.reload.name).to eq("Sam")
    end
  end

  describe "DELETE /api/mobile/v1/bill_participants/:id" do
    let(:bill) { create(:bill, user: user, session_status: :open) }
    let(:receipt) { create(:receipt, bill: bill) }
    let(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 2_000) }
    let!(:host) { create(:bill_participant, bill: bill, is_host: true) }
    let!(:participant) { create(:bill_participant, bill: bill) }

    it "removes a participant and rebalances shared assignments" do
      create(:item_assignment, receipt_item: item, bill_participant: host, amount_cents: 1_000)
      create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 1_000)

      delete "/api/mobile/v1/bill_participants/#{participant.id}"

      expect(response).to have_http_status(:ok)
      expect(BillParticipant.exists?(participant.id)).to be(false)
      expect(item.item_assignments.reload.sole).to have_attributes(
        bill_participant_id: host.id,
        amount_cents: item.total_cents
      )
      expect(response.parsed_body.dig("bill_summary", "participants").pluck("id")).to contain_exactly(host.id)
    end

    it "clears a solely claimed item" do
      create(
        :item_assignment,
        receipt_item: item,
        bill_participant: participant,
        amount_cents: item.total_cents
      )

      delete "/api/mobile/v1/bill_participants/#{participant.id}"

      expect(response).to have_http_status(:ok)
      expect(item.item_assignments.reload).to be_empty
      expect(response.parsed_body.dig("bill_summary", "bill", "unassigned_items_count")).to eq(1)
    end

    it "does not remove the host" do
      delete "/api/mobile/v1/bill_participants/#{host.id}"

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(BillParticipant.exists?(host.id)).to be(true)
    end

    it "does not remove participants after finalization" do
      bill.update!(session_status: :finalized)

      delete "/api/mobile/v1/bill_participants/#{participant.id}"

      expect(response).to have_http_status(:unprocessable_content)
      expect(BillParticipant.exists?(participant.id)).to be(true)
    end

    it "does not remove another user's participant" do
      other = create(:bill_participant, bill: create(:bill, user: create(:user)))

      delete "/api/mobile/v1/bill_participants/#{other.id}"

      expect(response).to have_http_status(:not_found)
      expect(BillParticipant.exists?(other.id)).to be(true)
    end
  end
end
