# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bill total calculations" do
  let(:bill) { create(:bill, title: "Totals Test") }
  let(:receipt) { create(:receipt, bill: bill) }

  def summary_for
    Bills::Summary.call(bill.reload)
  end

  before do
    create(:receipt_item, bill: bill, receipt: receipt, name: "Main", unit_price_cents: 10_000, total_cents: 10_000, position: 0)
  end

  it "does not add VAT included rows when affects_total is false" do
    create(:receipt_adjustment, receipt: receipt, label: "VAT (included)", kind: :tax, amount_cents: 1_500, affects_total: false, position: 0)

    expect(summary_for[:totals][:bill_total_cents]).to eq(10_000)
  end

  it "adds service fee when affects_total is true" do
    create(:receipt_adjustment, receipt: receipt, label: "Service charge", kind: :service_fee, amount_cents: 1_000, affects_total: true, position: 0)

    expect(summary_for[:totals][:bill_total_cents]).to eq(11_000)
  end

  it "adds tip when affects_total is true" do
    create(:receipt_adjustment, receipt: receipt, label: "Tip", kind: :tip, amount_cents: 2_000, affects_total: true, position: 0)

    expect(summary_for[:totals][:bill_total_cents]).to eq(12_000)
  end

  it "subtracts discount when affects_total is true and amount is negative" do
    create(:receipt_adjustment, receipt: receipt, label: "Discount", kind: :discount, amount_cents: -1_500, affects_total: true, position: 0)

    expect(summary_for[:totals][:bill_total_cents]).to eq(8_500)
  end

  it "uses receipt.total_cents when stored total is greater than zero" do
    receipt.update!(total_cents: 99_000)

    expect(summary_for[:totals][:bill_total_cents]).to eq(99_000)
  end

  it "falls back to calculated total when receipt.total_cents is zero" do
    receipt.update!(total_cents: 0)
    create(:receipt_adjustment, receipt: receipt, label: "Tip", kind: :tip, amount_cents: 500, affects_total: true, position: 0)

    expect(summary_for[:totals][:bill_total_cents]).to eq(10_500)
  end

  it "does not double-count display-only subtotal rows" do
    create(:receipt_adjustment, receipt: receipt, label: "Subtotal", kind: :subtotal, amount_cents: 10_000, affects_total: false, position: 0)
    create(:receipt_adjustment, receipt: receipt, label: "Service charge", kind: :service_fee, amount_cents: 1_000, affects_total: true, position: 1)

    expect(summary_for[:totals][:bill_total_cents]).to eq(11_000)
  end

  it "keeps assigned and unassigned totals correct with mixed adjustments" do
    participant = create(:bill_participant, bill: bill)
    item = bill.receipt_items.first
    create(:item_assignment, receipt_item: item, bill_participant: participant, amount_cents: 4_000, split_method: :equal)
    create(:receipt_adjustment, receipt: receipt, label: "Tip", kind: :tip, amount_cents: 1_000, affects_total: true, position: 0)

    totals = summary_for[:totals]
    expect(totals[:bill_total_cents]).to eq(11_000)
    expect(totals[:assigned_total_cents]).to eq(4_000)
    expect(totals[:unassigned_total_cents]).to eq(7_000)
  end
end
