# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cross-bill scoping", type: :request do
  let!(:owner) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:owner_bill) { create(:bill, user: owner, title: "Owner Bill") }
  let!(:other_bill) { create(:bill, user: other_user, title: "Other Bill") }
  let!(:owner_receipt) { create(:receipt, bill: owner_bill) }
  let!(:other_receipt) { create(:receipt, bill: other_bill) }
  let!(:owner_item) { create(:receipt_item, bill: owner_bill, receipt: owner_receipt, total_cents: 5_000) }
  let!(:other_item) { create(:receipt_item, bill: other_bill, receipt: other_receipt, total_cents: 3_000) }
  let!(:owner_participant) { create(:bill_participant, bill: owner_bill, name: "Owner") }
  let!(:other_participant) { create(:bill_participant, bill: other_bill, name: "Other") }

  before do
    authorize_mobile_user(owner)
  end

  it "cannot assign a receipt item to a participant from another bill" do
    put "/api/mobile/v1/receipt_items/#{owner_item.id}/assignments", params: {
      participant_ids: [ other_participant.id ],
      split_method: "equal"
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(api_error(response.parsed_body)["details"]["participant_ids"]).to be_present
    expect(owner_item.reload.item_assignments).to be_empty
  end

  it "cannot update a participant from another bill" do
    patch "/api/mobile/v1/bill_participants/#{other_participant.id}", params: {
      participant: { name: "Hacker" }
    }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "cannot update a receipt item from another bill" do
    patch "/api/mobile/v1/receipt_items/#{other_item.id}", params: {
      receipt_item: { name: "Hacker" }
    }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "cannot create an adjustment on another user's receipt" do
    post "/api/mobile/v1/receipts/#{other_receipt.id}/adjustments", params: {
      receipt_adjustment: { label: "Tax", kind: "tax", amount_cents: 100 }
    }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "cannot update an adjustment from another bill's receipt" do
    adjustment = create(:receipt_adjustment, receipt: other_receipt, label: "VAT", kind: :tax, amount_cents: 100)

    patch "/api/mobile/v1/receipt_adjustments/#{adjustment.id}", params: {
      receipt_adjustment: { label: "Hacker" }
    }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "cannot delete an adjustment from another bill's receipt" do
    adjustment = create(:receipt_adjustment, receipt: other_receipt, label: "Tip", kind: :tip, amount_cents: 100)

    delete "/api/mobile/v1/receipt_adjustments/#{adjustment.id}"

    expect(response).to have_http_status(:not_found)
    expect(ReceiptAdjustment.exists?(adjustment.id)).to be(true)
  end

  it "bulk assignment only affects the target bill" do
    create(:bill_participant, bill: owner_bill, name: "Sam")
    create(:receipt_item, bill: other_bill, receipt: other_receipt, total_cents: 2_000, position: 1)

    post "/api/mobile/v1/bills/#{owner_bill.id}/split_all_equally"

    expect(response).to have_http_status(:ok)
    expect(owner_item.reload.item_assignments).not_to be_empty
    expect(other_item.reload.item_assignments).to be_empty
  end

  it "cannot upload a receipt image to another user's bill" do
    post "/api/mobile/v1/bills/#{other_bill.id}/receipt_images", params: {
      image: receipt_image_upload
    }

    expect(response).to have_http_status(:not_found)
  end
end
