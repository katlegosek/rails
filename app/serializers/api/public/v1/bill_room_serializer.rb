# frozen_string_literal: true

class Api::Public::V1::BillRoomSerializer
  def initialize(bill, current_participant: nil)
    @bill = bill
    @current_participant = current_participant
  end

  def as_json(*)
    {
      bill: {
        id: bill.id,
        title: bill.display_title,
        session_status: bill.session_status,
        total_cents: Bills::Summary.bill_total_cents_for(bill),
        currency: bill.receipt&.currency || "ZAR"
      },
      receipt_items: Api::Mobile::V1::ReceiptItemSerializer.collection(
        bill.receipt_items.order(:position)
      ),
      participants: Api::Mobile::V1::BillParticipantSerializer.collection(
        bill.bill_participants.order(:seat_index, :id)
      ),
      item_assignments: Api::Mobile::V1::ItemAssignmentSerializer.collection(
        bill.item_assignments
      ),
      current_participant_id: current_participant&.id
    }
  end

  private

  attr_reader :bill, :current_participant
end
