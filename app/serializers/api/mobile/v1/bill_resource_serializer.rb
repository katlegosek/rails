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
      session_status: object.session_status,
      share_token: object.share_token,
      share_url: share_url,
      confirmed_at: object.confirmed_at,
      finalized_at: object.finalized_at,
      total_cents: Bills::Summary.bill_total_cents_for(object),
      receipt_name: object.receipt_name,
      receipt_date: object.receipt_date,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end

  private

  def share_url
    return unless object.share_token

    base_url = ENV["WEB_APP_URL"].presence || ENV["FRONTEND_URL"].presence
    return unless base_url

    "#{base_url.delete_suffix("/")}/b/#{object.share_token}"
  end
end
