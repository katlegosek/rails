# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessReceiptJob do
  let(:bill) { create(:bill) }
  let(:receipt) { create(:receipt, bill: bill, status: :processing) }
  let!(:processing_run) { create(:receipt_processing_run, receipt: receipt, provider: "fake_ocr", status: :pending) }

  it "marks the receipt ready and completes the processing run" do
    described_class.perform_now(receipt.id)

    receipt.reload
    processing_run.reload

    expect(receipt).to be_ready
    expect(processing_run).to be_completed
    expect(receipt.receipt_items.count).to be_between(6, 8)
    expect(processing_run.raw_ocr_text).to be_present
    expect(processing_run.raw_ai_response["debug"]).to include("simulated" => true)
  end
end
