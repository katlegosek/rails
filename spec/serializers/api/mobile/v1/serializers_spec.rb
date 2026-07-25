# frozen_string_literal: true

require "rails_helper"

# Locks the JSON key set produced by each mobile API serializer so we
# don't accidentally add / rename / drop a field without an intentional
# change. Value-level expectations stay in the request specs where they
# can see the full controller wiring.
RSpec.describe "Api::Mobile::V1 serializers", type: :model do
  let(:user) { create(:user) }
  let(:bill) { create(:bill, user: user) }
  let(:receipt) { create(:receipt, bill: bill) }
  let(:receipt_item) { create(:receipt_item, bill: bill, receipt: receipt) }
  let(:participant) { create(:bill_participant, bill: bill) }

  describe Api::Mobile::V1::AuthUserSerializer do
    it "exposes the public-facing user fields and falls back to email" do
      user = build_stubbed(:user, email: "u@example.com", first_name: nil, last_name: nil)

      json = described_class.new(user).as_json

      expect(json.keys).to match_array(%i[id email first_name last_name full_name])
      expect(json[:full_name]).to eq("u@example.com")
    end
  end

  describe Api::Mobile::V1::BillResourceSerializer do
    it "matches the inner bill payload shape" do
      json = described_class.new(bill).as_json

      expect(json.keys).to match_array(
        %i[id title status session_status share_token share_url confirmed_at finalized_at
           total_cents receipt_name receipt_date created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::BillListItemSerializer do
    it "matches the index list-item shape" do
      json = described_class.new(bill).as_json

      expect(json.keys).to match_array(
        %i[id title status total_cents participants_count receipt_name receipt_date created_at]
      )
    end
  end

  describe Api::Mobile::V1::BillSerializer do
    it "composes nested resource serializers" do
      _ = receipt
      _ = receipt_item
      _ = participant
      bill.reload

      json = described_class.new(bill).as_json

      expect(json.keys).to match_array(
        %i[bill receipt receipt_items receipt_adjustments bill_participants item_assignments]
      )
      expect(json[:receipt][:id]).to eq(receipt.id)
      expect(json[:receipt_items].first[:id]).to eq(receipt_item.id)
      expect(json[:bill_participants].first[:id]).to eq(participant.id)
    end

    it "renders a nil receipt and empty adjustments when the bill has no receipt" do
      json = described_class.new(bill).as_json

      expect(json[:receipt]).to be_nil
      expect(json[:receipt_adjustments]).to eq([])
    end
  end

  describe Api::Mobile::V1::ReceiptSerializer do
    it "matches the receipt payload shape" do
      json = described_class.new(receipt).as_json

      expect(json.keys).to match_array(
        %i[id bill_id status merchant_name receipt_date subtotal_cents total_cents
           currency tax_cents service_fee_cents tip_cents discount_cents created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::ReceiptStatusSerializer do
    it "matches the trimmed status shape" do
      json = described_class.new(receipt).as_json

      expect(json.keys).to match_array(%i[id status])
    end
  end

  describe Api::Mobile::V1::ReceiptItemSerializer do
    it "matches the receipt item shape and coerces quantity to Float" do
      item = build_stubbed(:receipt_item, bill: bill, receipt: receipt, quantity: 2)

      json = described_class.new(item).as_json

      expect(json.keys).to match_array(
        %i[id bill_id receipt_id name quantity unit_price_cents total_cents
           category icon_key position confidence created_at updated_at]
      )
      expect(json[:quantity]).to be_a(Float)
    end
  end

  describe Api::Mobile::V1::ReceiptAdjustmentSerializer do
    it "matches the adjustment shape" do
      adjustment = create(:receipt_adjustment, receipt: receipt)

      json = described_class.new(adjustment).as_json

      expect(json.keys).to match_array(
        %i[id receipt_id label kind amount_cents affects_total position created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::BillParticipantSerializer do
    it "matches the participant shape" do
      json = described_class.new(participant).as_json

      expect(json.keys).to match_array(
        %i[id bill_id name initials avatar_background_color avatar_text_color
           seat_index is_host settled created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::ItemAssignmentSerializer do
    it "matches the assignment shape" do
      assignment = create(:item_assignment, receipt_item: receipt_item, bill_participant: participant)

      json = described_class.new(assignment).as_json

      expect(json.keys).to match_array(
        %i[id receipt_item_id bill_participant_id amount_cents split_method created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::ReceiptProcessingRunSerializer do
    it "matches the processing-run shape" do
      run = create(:receipt_processing_run, receipt: receipt)

      json = described_class.new(run).as_json

      expect(json.keys).to match_array(
        %i[id receipt_id provider status error_message started_at completed_at created_at updated_at]
      )
    end
  end

  describe Api::Mobile::V1::BillSummarySerializer do
    it "delegates to Bills::Summary and returns the summary shape" do
      json = described_class.new(bill).as_json

      expect(json.keys).to match_array(%i[bill totals participants receipt_adjustments])
    end
  end

  describe Api::Mobile::V1::AuthSessionSerializer do
    it "wraps a Doorkeeper access token + user into the session shape" do
      access_token = instance_double(
        Doorkeeper::AccessToken,
        token: "access",
        refresh_token: "refresh",
        expires_in: 7_200
      )

      json = described_class.new(access_token: access_token, user: user).as_json

      expect(json.keys).to match_array(%i[access_token refresh_token token_type expires_in user])
      expect(json[:token_type]).to eq("Bearer")
      expect(json[:user][:id]).to eq(user.id)
    end
  end
end
