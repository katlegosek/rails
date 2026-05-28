# frozen_string_literal: true

# Serializes a single ItemAssignment. Mirrors the previous
# `item_assignment_payload` helper exactly.
class Api::Mobile::V1::ItemAssignmentSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      receipt_item_id: object.receipt_item_id,
      bill_participant_id: object.bill_participant_id,
      amount_cents: object.amount_cents,
      split_method: object.split_method,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
