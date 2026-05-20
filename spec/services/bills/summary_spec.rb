# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bills::Summary do
  subject(:summary) { described_class.call(bill) }

  let(:bill) { create(:bill, status: :active) }
  let(:receipt) { create(:receipt, bill: bill, status: :confirmed) }

  describe "partially assigned bill" do
    let!(:katlego) do
      create(:bill_participant, bill: bill, name: "Katlego", initials: "KM", seat_index: 0, is_host: true, settled: false)
    end
    let!(:sam) do
      create(:bill_participant, bill: bill, name: "Sam", initials: "S", seat_index: 1, settled: false)
    end
    let!(:burrata) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Burrata", unit_price_cents: 9_000, total_cents: 9_000, position: 0)
    end
    let!(:lamb) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Lamb", unit_price_cents: 14_000, total_cents: 14_000, position: 1)
    end
    let!(:wine) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Wine", unit_price_cents: 20_000, total_cents: 20_000, position: 2)
    end
    let!(:tax) do
      create(:receipt_adjustment, receipt: receipt, label: "VAT", kind: :tax, amount_cents: 3_450, included_in_total: true, position: 1)
    end
    let!(:delivery) do
      create(:receipt_adjustment, receipt: receipt, label: "Delivery", kind: :delivery_fee, amount_cents: 500, included_in_total: false, position: 2)
    end

    before do
      create(:item_assignment, receipt_item: burrata, bill_participant: katlego, amount_cents: 4_500, split_method: :equal)
      create(:item_assignment, receipt_item: burrata, bill_participant: sam, amount_cents: 4_500, split_method: :equal)
      create(:item_assignment, receipt_item: lamb, bill_participant: katlego, amount_cents: 14_000, split_method: :custom)
      create(
        :receipt_processing_run,
        receipt: receipt,
        status: :completed,
        raw_ai_response: { title: "Observatory Small Plates", merchant: "Observatory Restaurant" }
      )
    end

    it "returns bill summary fields" do
      expect(summary[:bill]).to eq(
        id: bill.id,
        title: "Observatory Small Plates",
        status: "active",
        total_cents: 43_500,
        items_count: 3,
        assigned_items_count: 2,
        unassigned_items_count: 1
      )
    end

    it "returns totals" do
      expect(summary[:totals]).to eq(
        bill_total_cents: 43_500,
        assigned_total_cents: 23_000,
        unassigned_total_cents: 20_500,
        settled_total_cents: 0,
        outstanding_total_cents: 23_000
      )
    end

    it "returns participant breakdowns" do
      katlego_summary = summary[:participants].find { |participant| participant[:name] == "Katlego" }
      sam_summary = summary[:participants].find { |participant| participant[:name] == "Sam" }

      expect(katlego_summary).to include(
        amount_due_cents: 18_500,
        assigned_items_count: 2,
        settled: false
      )
      expect(sam_summary).to include(
        amount_due_cents: 4_500,
        assigned_items_count: 1,
        settled: false
      )
    end

    it "returns receipt adjustments" do
      expect(summary[:receipt_adjustments]).to contain_exactly(
        {
          id: tax.id,
          label: "VAT",
          kind: "tax",
          amount_cents: 3_450,
          included_in_total: true,
          position: 1
        },
        {
          id: delivery.id,
          label: "Delivery",
          kind: "delivery_fee",
          amount_cents: 500,
          included_in_total: false,
          position: 2
        }
      )
    end
  end

  describe "fully assigned bill with settled participants" do
    let!(:katlego) do
      create(:bill_participant, bill: bill, name: "Katlego", settled: true, seat_index: 0)
    end
    let!(:alex) do
      create(:bill_participant, bill: bill, name: "Alex", settled: true, seat_index: 1)
    end
    let!(:burger) do
      create(:receipt_item, bill: bill, receipt: receipt, name: "Burger", unit_price_cents: 8_000, total_cents: 8_000, position: 0)
    end

    before do
      create(:item_assignment, receipt_item: burger, bill_participant: katlego, amount_cents: 4_000, split_method: :equal)
      create(:item_assignment, receipt_item: burger, bill_participant: alex, amount_cents: 4_000, split_method: :equal)
    end

    it "uses receipt stored total when present" do
      allow(bill.receipt).to receive(:stored_total_cents).and_return(8_000)

      expect(summary[:totals][:bill_total_cents]).to eq(8_000)
      expect(summary[:totals][:unassigned_total_cents]).to eq(0)
      expect(summary[:totals][:settled_total_cents]).to eq(8_000)
      expect(summary[:totals][:outstanding_total_cents]).to eq(0)
    end
  end
end
