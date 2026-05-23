# frozen_string_literal: true

require "rails_helper"

# Smoke test that every Api::Mobile::V1 protected endpoint requires a bearer
# token. The point isn't full coverage of each action's behaviour — it's a
# regression guard so a future commit cannot accidentally make a protected
# resource publicly reachable.
RSpec.describe "Mobile API protected endpoints", type: :request do
  # The shared `mobile api current user` context (see spec/support/mobile_api.rb)
  # is auto-included for everything under spec/requests/api/mobile/v1/. Clear the
  # headers here so these examples make unauthenticated requests.
  before { @mobile_auth_headers = {} }

  let(:owner) { create(:user) }
  let!(:bill) { create(:bill, user: owner) }
  let!(:participant) { create(:bill_participant, bill: bill) }
  let!(:receipt) { create(:receipt, bill: bill) }
  let!(:receipt_item) { create(:receipt_item, bill: bill, receipt: receipt) }
  let!(:adjustment) { create(:receipt_adjustment, receipt: receipt, label: "VAT", kind: :tax, amount_cents: 100) }

  # Each row is [http_method, path, optional params]. Params are kept minimal —
  # we only care that the request is rejected before the controller does any
  # work.
  endpoints = [
    [ :get, "/api/mobile/v1/bills" ],
    [ :post, "/api/mobile/v1/bills" ],
    [ :get, "/api/mobile/v1/bills/%<bill_id>d" ],
    [ :get, "/api/mobile/v1/bills/%<bill_id>d/summary" ],
    [ :post, "/api/mobile/v1/bills/%<bill_id>d/split_all_equally" ],
    [ :post, "/api/mobile/v1/bills/%<bill_id>d/split_unassigned_equally" ],
    [ :delete, "/api/mobile/v1/bills/%<bill_id>d/assignments" ],
    [ :post, "/api/mobile/v1/bills/%<bill_id>d/participants" ],
    [ :post, "/api/mobile/v1/bills/%<bill_id>d/receipt_items" ],
    [ :post, "/api/mobile/v1/bills/%<bill_id>d/receipt_images" ],
    [ :patch, "/api/mobile/v1/bill_participants/%<participant_id>d" ],
    [ :delete, "/api/mobile/v1/bill_participants/%<participant_id>d" ],
    [ :patch, "/api/mobile/v1/receipt_items/%<item_id>d" ],
    [ :delete, "/api/mobile/v1/receipt_items/%<item_id>d" ],
    [ :put, "/api/mobile/v1/receipt_items/%<item_id>d/assignments" ],
    [ :delete, "/api/mobile/v1/receipt_items/%<item_id>d/assignments" ],
    [ :get, "/api/mobile/v1/receipts/%<receipt_id>d" ],
    [ :post, "/api/mobile/v1/receipts/%<receipt_id>d/adjustments" ],
    [ :patch, "/api/mobile/v1/receipt_adjustments/%<adjustment_id>d" ],
    [ :delete, "/api/mobile/v1/receipt_adjustments/%<adjustment_id>d" ]
  ]

  endpoints.each do |(method, path_template)|
    it "#{method.upcase} #{path_template} requires a valid bearer token" do
      path = format(path_template,
        bill_id: bill.id,
        participant_id: participant.id,
        item_id: receipt_item.id,
        receipt_id: receipt.id,
        adjustment_id: adjustment.id
      )

      # Use the bare ActionDispatch request driver so we don't carry over any
      # auth headers set by support helpers.
      process(method, path, headers: {})

      expect(response).to have_http_status(:unauthorized),
        "expected #{method.upcase} #{path} to require auth, got #{response.status}"
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end
  end
end
