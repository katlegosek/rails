# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::BillParticipants", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "POST /api/mobile/v1/bills/:bill_id/participants" do
    let(:bill) { create(:bill, user: user) }

    it "creates a participant and returns bill summary" do
      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: {
          name: "Sam",
          initials: "S",
          avatar_background_color: "#059669",
          avatar_text_color: "#FFFFFF",
          seat_index: 1,
          is_host: false,
          settled: false
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body

      expect(body["participant"]).to include(
        "bill_id" => bill.id,
        "name" => "Sam",
        "initials" => "S",
        "seat_index" => 1,
        "is_host" => false,
        "settled" => false
      )
      expect(body["bill_summary"]["bill"]["id"]).to eq(bill.id)
      expect(body["bill_summary"]["participants"].size).to eq(1)
    end

    it "ensures only one host when creating a host participant" do
      existing_host = create(:bill_participant, bill: bill, name: "Katlego", is_host: true)

      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: { name: "Alex", is_host: true }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(existing_host.reload.is_host).to be(false)
      expect(response.parsed_body["participant"]["is_host"]).to be(true)
    end

    it "returns validation errors when name is missing" do
      post "/api/mobile/v1/bills/#{bill.id}/participants", params: {
        participant: { name: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(api_error(response.parsed_body)["details"]).to be_present
    end

    it "returns not found when the bill belongs to another user" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/participants", params: {
        participant: { name: "Sam" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Bill not found")
    end
  end

  describe "PATCH /api/mobile/v1/bill_participants/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:participant) { create(:bill_participant, bill: bill, name: "Sam", is_host: false) }

    it "updates a participant and returns bill summary" do
      patch "/api/mobile/v1/bill_participants/#{participant.id}", params: {
        participant: { name: "Samuel", settled: true, is_host: true }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["participant"]).to include(
        "id" => participant.id,
        "name" => "Samuel",
        "settled" => true,
        "is_host" => true
      )
      expect(body["bill_summary"]["participants"].find { |p| p["id"] == participant.id }).to include(
        "name" => "Samuel",
        "settled" => true
      )
    end

    it "clears the previous host when updating a participant to host" do
      host = create(:bill_participant, bill: bill, name: "Katlego", is_host: true)

      patch "/api/mobile/v1/bill_participants/#{participant.id}", params: {
        participant: { is_host: true }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(host.reload.is_host).to be(false)
      expect(participant.reload.is_host).to be(true)
    end

    it "returns not found for another user's participant" do
      other_participant = create(:bill_participant, bill: create(:bill, user: create(:user)))

      patch "/api/mobile/v1/bill_participants/#{other_participant.id}", params: {
        participant: { name: "Hacker" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Participant not found")
    end
  end

  describe "DELETE /api/mobile/v1/bill_participants/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:participant) { create(:bill_participant, bill: bill, name: "Sam") }
    let(:receipt) { create(:receipt, bill: bill) }
    let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 5_000) }
    let!(:assignment) { create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 5_000) }

    it "deletes the participant, their assignments, and returns bill summary" do
      delete "/api/mobile/v1/bill_participants/#{participant.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["participant"]).to include("id" => participant.id, "name" => "Sam")
      expect(BillParticipant.exists?(participant.id)).to be(false)
      expect(ItemAssignment.exists?(assignment.id)).to be(false)
      expect(body["bill_summary"]["participants"]).to eq([])
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(0)
    end

    it "returns not found for another user's participant" do
      other_participant = create(:bill_participant, bill: create(:bill, user: create(:user)))

      delete "/api/mobile/v1/bill_participants/#{other_participant.id}"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Participant not found")
    end
  end
end
