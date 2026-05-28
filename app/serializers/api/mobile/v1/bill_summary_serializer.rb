# frozen_string_literal: true

# Composite summary payload for `GET /api/mobile/v1/bills/:id/summary`,
# and the `bill_summary:` key embedded in many write responses
# (participants/items/adjustments/assignments).
#
# Delegates the actual aggregation to `Bills::Summary` so we don't
# duplicate (or drift from) the totals math, and only owns the wire
# shape (`{ bill:, totals:, participants:, receipt_adjustments: }`).
#
# Callers are responsible for passing a bill that has been scoped to the
# current user and eager-loaded with the associations Bills::Summary
# expects (see `Api::Mobile::V1::BaseController#bill_for_summary`).
class Api::Mobile::V1::BillSummarySerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    Bills::Summary.call(object)
  end
end
