# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReceiptItems::ReplaceAssignments do
  let(:bill) { create(:bill) }
  let!(:receipt) { create(:receipt, bill: bill) }
  let!(:item) { create(:receipt_item, bill: bill, receipt: receipt, total_cents: 100, position: 0) }
  let!(:katlego) { create(:bill_participant, bill: bill, name: "Katlego") }
  let!(:sam) { create(:bill_participant, bill: bill, name: "Sam") }
  let!(:jordan) { create(:bill_participant, bill: bill, name: "Jordan") }

  describe ".call" do
    it "replaces assignments with an equal split and distributes remainder cents" do
      described_class.call(
        receipt_item: item,
        participant_ids: [ katlego.id, sam.id, jordan.id ],
        split_method: "equal"
      )

      amounts = [ katlego.id, sam.id, jordan.id ].map do |participant_id|
        item.reload.item_assignments.find_by!(bill_participant_id: participant_id).amount_cents
      end
      expect(amounts).to eq([ 34, 33, 33 ])
      expect(amounts.sum).to eq(100)
      expect(item.item_assignments.pluck(:split_method).uniq).to eq([ "equal" ])
    end

    it "clears assignments when participant_ids is empty" do
      create(:item_assignment, receipt_item: item, bill_participant: katlego, amount_cents: 100, split_method: :equal)

      described_class.call(
        receipt_item: item,
        participant_ids: [],
        split_method: "equal"
      )

      expect(item.reload.item_assignments).to be_empty
    end

    it "rejects unsupported split methods" do
      expect do
        described_class.call(
          receipt_item: item,
          participant_ids: [ katlego.id ],
          split_method: "custom"
        )
      end.to raise_error(ReceiptItems::ReplaceAssignments::Invalid) do |error|
        expect(error.errors[:split_method]).to include("must be equal")
      end
    end

    it "rejects participants from another bill" do
      outsider = create(:bill_participant, bill: create(:bill))

      expect do
        described_class.call(
          receipt_item: item,
          participant_ids: [ katlego.id, outsider.id ],
          split_method: "equal"
        )
      end.to raise_error(ReceiptItems::ReplaceAssignments::Invalid) do |error|
        expect(error.errors[:participant_ids]).to include("must belong to the same bill as the receipt item")
      end
    end
  end
end
