# frozen_string_literal: true

module Api::Mobile::V1::ResponsePayloads::AssignmentPayloads
  extend ActiveSupport::Concern

  private

  def item_assignment_payload(assignment)
    {
      id: assignment.id,
      receipt_item_id: assignment.receipt_item_id,
      bill_participant_id: assignment.bill_participant_id,
      amount_cents: assignment.amount_cents,
      split_method: assignment.split_method,
      created_at: assignment.created_at,
      updated_at: assignment.updated_at
    }
  end
end
