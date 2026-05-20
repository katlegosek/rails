# frozen_string_literal: true

require "rails_helper"

RSpec.describe Receipts::FakeOcrProcessor do
  let(:bill) { create(:bill) }
  let(:receipt) { create(:receipt, bill: bill) }
  let!(:processing_run) { create(:receipt_processing_run, receipt: receipt, provider: "fake_ocr", status: :processing) }

  it "creates receipt items and adjustments" do
    described_class.call(receipt, processing_run: processing_run)

    expect(receipt.receipt_items.count).to be_between(6, 8)
    expect(receipt.receipt_adjustments.count).to eq(3)
    expect(processing_run.reload.raw_ocr_text).to include("Observatory Small Plates")
    expect(processing_run.raw_ai_response["merchant"]).to eq("Observatory Small Plates")
  end

  it "replaces existing extracted data on subsequent runs" do
    described_class.call(receipt, processing_run: processing_run)
    first_item_ids = receipt.receipt_items.pluck(:id)

    described_class.call(receipt, processing_run: processing_run)

    expect(receipt.receipt_items.pluck(:id)).not_to eq(first_item_ids)
    expect(receipt.receipt_items.count).to be_between(6, 8)
    expect(receipt.receipt_adjustments.count).to eq(3)
  end

  it "does not remove bill participants" do
    participant = create(:bill_participant, bill: bill)

    described_class.call(receipt, processing_run: processing_run)

    expect(BillParticipant.exists?(participant.id)).to be(true)
  end
end
