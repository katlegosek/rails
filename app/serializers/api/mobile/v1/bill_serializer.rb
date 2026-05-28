# frozen_string_literal: true

# Composite show payload for `GET /api/mobile/v1/bills/:id`.
#
# Composes the smaller resource serializers so each piece can be reused
# (and tested) independently. Mirrors the previous `bill_show_json`
# controller helper exactly, including ordering of receipt items /
# adjustments / participants and the empty array fallback when the bill
# has no receipt.
class Api::Mobile::V1::BillSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      bill: Api::Mobile::V1::BillResourceSerializer.new(object).as_json,
      receipt: serialized_receipt,
      receipt_items: serialized_receipt_items,
      receipt_adjustments: serialized_receipt_adjustments,
      bill_participants: serialized_bill_participants,
      item_assignments: serialized_item_assignments
    }
  end

  private

  def serialized_receipt
    return nil unless object.receipt

    Api::Mobile::V1::ReceiptSerializer.new(object.receipt).as_json
  end

  def serialized_receipt_items
    Api::Mobile::V1::ReceiptItemSerializer.collection(
      object.receipt_items.order(:position)
    )
  end

  def serialized_receipt_adjustments
    adjustments = object.receipt&.receipt_adjustments&.order(:position)
    return [] unless adjustments

    Api::Mobile::V1::ReceiptAdjustmentSerializer.collection(adjustments)
  end

  def serialized_bill_participants
    Api::Mobile::V1::BillParticipantSerializer.collection(
      object.bill_participants.order(:seat_index, :id)
    )
  end

  def serialized_item_assignments
    Api::Mobile::V1::ItemAssignmentSerializer.collection(object.item_assignments)
  end
end
