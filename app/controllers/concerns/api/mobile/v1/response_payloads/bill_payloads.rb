# frozen_string_literal: true

module Api::Mobile::V1::ResponsePayloads::BillPayloads
  extend ActiveSupport::Concern

  private

  def bill_index_payload(bill)
    {
      id: bill.id,
      title: bill.display_title,
      status: bill.status,
      total_cents: Bills::Summary.bill_total_cents_for(bill),
      participants_count: bill.bill_participants.size,
      receipt_name: bill.receipt_name,
      receipt_date: bill.receipt_date,
      created_at: bill.created_at
    }
  end

  def bill_payload(bill)
    {
      id: bill.id,
      title: bill.display_title,
      status: bill.status,
      total_cents: Bills::Summary.bill_total_cents_for(bill),
      receipt_name: bill.receipt_name,
      receipt_date: bill.receipt_date,
      created_at: bill.created_at,
      updated_at: bill.updated_at
    }
  end

  def bill_summary_payload(bill)
    Bills::Summary.call(bill_for_summary(bill))
  end

  # Re-loads the bill scoped to the current user so summary computation always
  # uses an authorized record (and never accidentally includes another user's
  # data via the passed-in instance).
  def bill_for_summary(bill)
    current_mobile_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: :receipt_adjustments,
        receipt_items: :item_assignments,
        bill_participants: :item_assignments
      )
      .find(bill.id)
  end
end
