# frozen_string_literal: true

class Api::Mobile::V1::BillsController < Api::Mobile::V1::BaseController
  def index
    bills = current_mobile_user.bills
      .includes(:bill_participants, receipt: :receipt_processing_runs)
      .order(created_at: :desc)

    render json: { bills: bills.map { |bill| bill_index_payload(bill) } }
  end

  def show
    bill = current_mobile_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: %i[receipt_adjustments receipt_processing_runs],
        receipt_items: :item_assignments
      )
      .find_by(id: params[:id])

    return render_not_found("Bill not found") unless bill

    render json: bill_show_json(bill)
  end

  def summary
    bill = current_mobile_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: :receipt_adjustments,
        receipt_items: :item_assignments,
        bill_participants: :item_assignments
      )
      .find_by(id: params[:id])

    return render_not_found("Bill not found") unless bill

    render json: bill_summary_payload(bill)
  end

  private

  def bill_show_json(bill)
    {
      bill: bill_payload(bill),
      receipt: bill.receipt ? receipt_payload(bill.receipt) : nil,
      receipt_items: bill.receipt_items.order(:position).map { |item| receipt_item_payload(item) },
      receipt_adjustments: bill.receipt&.receipt_adjustments&.order(:position)&.map { |adjustment| receipt_adjustment_payload(adjustment) } || [],
      bill_participants: bill.bill_participants.order(:seat_index, :id).map { |participant| bill_participant_payload(participant) },
      item_assignments: bill.item_assignments.map { |assignment| item_assignment_payload(assignment) }
    }
  end
end
