# frozen_string_literal: true

# Trimmed bill shape for `GET /api/mobile/v1/bills` index responses.
# Mirrors the previous `bill_index_payload` helper exactly so we keep
# the existing `participants_count`/`receipt_name`/`receipt_date`
# fields the mobile app already consumes.
class Api::Mobile::V1::BillListItemSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      title: object.display_title,
      status: object.status,
      total_cents: Bills::Summary.bill_total_cents_for(object),
      participants_count: object.bill_participants.size,
      receipt_name: object.receipt_name,
      receipt_date: object.receipt_date,
      created_at: object.created_at
    }
  end
end
