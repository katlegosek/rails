# frozen_string_literal: true

# Aggregate concern that wires every mobile API JSON payload helper into one
# include. Add new domain payloads as separate concerns under
# `app/controllers/concerns/api/mobile/v1/response_payloads/` and include them
# here so controllers only need a single `include Api::Mobile::V1::ResponsePayloads`.
module Api::Mobile::V1::ResponsePayloads
  extend ActiveSupport::Concern

  include Api::Mobile::V1::ResponsePayloads::AuthPayloads
  include Api::Mobile::V1::ResponsePayloads::BillPayloads
  include Api::Mobile::V1::ResponsePayloads::ReceiptPayloads
  include Api::Mobile::V1::ResponsePayloads::ParticipantPayloads
  include Api::Mobile::V1::ResponsePayloads::AssignmentPayloads
end
