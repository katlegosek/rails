# frozen_string_literal: true

# Trimmed Receipt payload returned by the receipt-image upload endpoint,
# which only needs to communicate processing status. Mirrors the
# previous `receipt_status_payload` helper exactly.
class Api::Mobile::V1::ReceiptStatusSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      status: object.status
    }
  end
end
