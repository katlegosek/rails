# frozen_string_literal: true

# Inner Bill resource shape (a single bill, not a composite payload).
#
# Used both standalone (e.g. `POST /api/mobile/v1/bills` create response)
# and as the nested `bill:` key inside the composite
# `Api::Mobile::V1::BillSerializer` show payload. Mirrors the previous
# `bill_payload` helper exactly.
class Api::Mobile::V1::BillResourceSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      title: object.display_title,
      status: object.status,
      total_cents: Bills::Summary.bill_total_cents_for(object),
      receipt_name: object.receipt_name,
      receipt_date: object.receipt_date,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
