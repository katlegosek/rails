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
  end
end
