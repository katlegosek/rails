# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::ReceiptItems", type: :request do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end

  describe "POST /api/mobile/v1/bills/:bill_id/receipt_items" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }

    it "creates a receipt item with calculated total and bill summary" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: {
          name: "Burrata",
          unit_price_cents: 9_500,
          quantity: 2,
          category: "starter",
          icon_key: "plate"
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body

      expect(body["receipt_item"]).to include(
        "bill_id" => bill.id,
        "receipt_id" => receipt.id,
        "name" => "Burrata",
        "quantity" => 2.0,
        "unit_price_cents" => 9_500,
        "total_cents" => 19_000,
        "category" => "starter",
        "position" => 0
      )
      expect(body["bill_summary"]["bill"]["items_count"]).to eq(1)
    end

    it "defaults quantity to 1 when blank" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: {
          name: "Wine",
          unit_price_cents: 22_000
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["receipt_item"]).to include(
        "quantity" => 1.0,
        "total_cents" => 22_000
      )
    end

    it "uses provided total_cents when given" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: {
          name: "Discounted item",
          unit_price_cents: 10_000,
          quantity: 2,
          total_cents: 15_000
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["receipt_item"]["total_cents"]).to eq(15_000)
    end

    it "returns validation errors when name is missing" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_items", params: {
        receipt_item: { unit_price_cents: 1_000 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_error(response.parsed_body)["code"]).to eq("validation_error")
      expect(api_error(response.parsed_body)["details"]).to be_present
    end

    it "returns not found when the bill belongs to another user" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/receipt_items", params: {
        receipt_item: { name: "Stolen", unit_price_cents: 100 }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Bill not found")
    end
  end

  describe "PATCH /api/mobile/v1/receipt_items/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:item) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_500, total_cents: 9_500, position: 0)
    end

    it "updates a receipt item and recalculates total when needed" do
      patch "/api/mobile/v1/receipt_items/#{item.id}", params: {
        receipt_item: { quantity: 2 }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt_item"]).to include(
        "id" => item.id,
        "quantity" => 2.0,
        "total_cents" => 19_000
      )
      expect(body["bill_summary"]["totals"]["bill_total_cents"]).to eq(19_000)
    end

    it "returns not found for another user's receipt item" do
      other_item = create(:receipt_item, bill: create(:bill, user: create(:user)))

      patch "/api/mobile/v1/receipt_items/#{other_item.id}", params: {
        receipt_item: { name: "Hacker" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Receipt item not found")
    end
  end

  describe "DELETE /api/mobile/v1/receipt_items/:id" do
    let(:bill) { create(:bill, user: user) }
    let!(:receipt) { create(:receipt, bill: bill) }
    let!(:participant) { create(:bill_participant, bill: bill) }
    let!(:item) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_500, total_cents: 9_500, position: 0)
    end
    let!(:assignment) { create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 9_500) }

    it "deletes the receipt item, its assignments, and returns bill summary" do
      delete "/api/mobile/v1/receipt_items/#{item.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body["receipt_item"]).to include("id" => item.id, "name" => "Burrata")
      expect(ReceiptItem.exists?(item.id)).to be(false)
      expect(ItemAssignment.exists?(assignment.id)).to be(false)
      expect(body["bill_summary"]["bill"]["items_count"]).to eq(0)
      expect(body["bill_summary"]["totals"]["assigned_total_cents"]).to eq(0)
    end

    it "returns not found for another user's receipt item" do
      other_item = create(:receipt_item, bill: create(:bill, user: create(:user)))

      delete "/api/mobile/v1/receipt_items/#{other_item.id}"

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Receipt item not found")
    end
  end
end
