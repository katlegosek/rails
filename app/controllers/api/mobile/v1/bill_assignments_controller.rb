# frozen_string_literal: true

class Api::Mobile::V1::BillAssignmentsController < Api::Mobile::V1::BaseController
  def split_all_equally
    bill = find_bill_for_current_user
    return render_not_found("Bill not found") unless bill

    apply_bulk_assignments(
      bill: bill,
      receipt_items: bill.receipt_items.includes(:item_assignments)
    )

    render_bill_summary_response(bill)
  end

  def split_unassigned_equally
    bill = find_bill_for_current_user
    return render_not_found("Bill not found") unless bill

    unassigned_items = bill.receipt_items
      .includes(:item_assignments)
      .select { |item| item.item_assignments.none? }

    apply_bulk_assignments(bill: bill, receipt_items: unassigned_items)

    render_bill_summary_response(bill)
  end

  def clear
    bill = find_bill_for_current_user
    return render_not_found("Bill not found") unless bill

    apply_bulk_assignments(
      bill: bill,
      receipt_items: bill.receipt_items.includes(:item_assignments),
      participant_ids: []
    )

    render_bill_summary_response(bill)
  end

  private

  def find_bill_for_current_user
    current_user.bills.find_by(id: params[:id])
  end

  def apply_bulk_assignments(bill:, receipt_items:, participant_ids: nil)
    validate_bill!(bill)

    participant_ids ||= bill.bill_participants.pluck(:id)

    ActiveRecord::Base.transaction do
      receipt_items.each do |receipt_item|
        ReceiptItems::ReplaceAssignments.call(
          receipt_item: receipt_item,
          participant_ids: participant_ids,
          split_method: "equal"
        )
      end
    end
  end

  def validate_bill!(bill)
    errors = {}
    errors[:participants] = [ "must have at least one participant" ] if bill.bill_participants.none?
    errors[:receipt_items] = [ "must have at least one receipt item" ] if bill.receipt_items.none?

    raise BillAssignments::Invalid, errors if errors.any?
  end

  def render_bill_summary_response(bill)
    render json: { bill_summary: bill_summary_payload(bill) }
  end
end
