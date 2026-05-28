# frozen_string_literal: true

# Serializes a single ReceiptAdjustment. Mirrors the previous
# `receipt_adjustment_payload` helper exactly.
class Api::Mobile::V1::ReceiptAdjustmentSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      receipt_id: object.receipt_id,
      label: object.label,
      kind: object.kind,
      amount_cents: object.amount_cents,
      affects_total: object.affects_total,
      position: object.position,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
