# frozen_string_literal: true

# Serializes a single ReceiptItem. Mirrors the previous
# `receipt_item_payload` helper exactly (quantity coerced to Float to
# avoid leaking BigDecimal/string JSON encoding to the mobile client).
class Api::Mobile::V1::ReceiptItemSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      bill_id: object.bill_id,
      receipt_id: object.receipt_id,
      name: object.name,
      quantity: object.quantity.to_f,
      unit_price_cents: object.unit_price_cents,
      total_cents: object.total_cents,
      category: object.category,
      icon_key: object.icon_key,
      position: object.position,
      confidence: object.confidence&.to_f,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
