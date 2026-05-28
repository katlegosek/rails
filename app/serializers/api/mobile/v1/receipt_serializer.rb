# frozen_string_literal: true

# Full Receipt resource for the show + index nested payloads.
# Mirrors the previous `receipt_payload` helper exactly.
class Api::Mobile::V1::ReceiptSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      bill_id: object.bill_id,
      status: object.status,
      merchant_name: object.merchant_name,
      receipt_date: object.receipt_date,
      subtotal_cents: object.subtotal_cents,
      total_cents: object.total_cents,
      currency: object.currency,
      tax_cents: object.tax_cents,
      service_fee_cents: object.service_fee_cents,
      tip_cents: object.tip_cents,
      discount_cents: object.discount_cents,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
