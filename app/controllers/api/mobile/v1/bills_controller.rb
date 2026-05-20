# frozen_string_literal: true

class Api::Mobile::V1::BillsController < Api::Mobile::V1::BaseController
  def index
    bills = current_user.bills
      .includes(:bill_participants, receipt: :receipt_processing_runs)
      .order(created_at: :desc)

    render json: { bills: bills.map { |bill| bill_index_json(bill) } }
  end

  def show
    bill = current_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: %i[receipt_adjustments receipt_processing_runs],
        receipt_items: :item_assignments
      )
      .find_by(id: params[:id])

    return render_not_found unless bill

    render json: bill_show_json(bill)
  end

  private

  def bill_index_json(bill)
    {
      id: bill.id,
      title: bill.display_title,
      status: bill.status,
      total_cents: bill.total_cents,
      participants_count: bill.bill_participants.size,
      receipt_name: bill.receipt_name,
      receipt_date: bill.receipt_date,
      created_at: bill.created_at
    }
  end

  def bill_show_json(bill)
    {
      bill: bill_json(bill),
      receipt: bill.receipt ? receipt_json(bill.receipt) : nil,
      receipt_items: bill.receipt_items.order(:position).map { |item| receipt_item_json(item) },
      receipt_adjustments: bill.receipt&.receipt_adjustments&.order(:position)&.map { |adjustment| receipt_adjustment_json(adjustment) } || [],
      bill_participants: bill.bill_participants.order(:seat_index, :id).map { |participant| bill_participant_json(participant) },
      item_assignments: bill.item_assignments.map { |assignment| item_assignment_json(assignment) }
    }
  end

  def bill_json(bill)
    {
      id: bill.id,
      title: bill.display_title,
      status: bill.status,
      total_cents: bill.total_cents,
      receipt_name: bill.receipt_name,
      receipt_date: bill.receipt_date,
      created_at: bill.created_at,
      updated_at: bill.updated_at
    }
  end

  def receipt_json(receipt)
    {
      id: receipt.id,
      bill_id: receipt.bill_id,
      status: receipt.status,
      created_at: receipt.created_at,
      updated_at: receipt.updated_at
    }
  end

  def receipt_item_json(item)
    {
      id: item.id,
      bill_id: item.bill_id,
      receipt_id: item.receipt_id,
      name: item.name,
      quantity: item.quantity.to_f,
      unit_price_cents: item.unit_price_cents,
      total_cents: item.total_cents,
      category: item.category,
      icon_key: item.icon_key,
      position: item.position,
      confidence: item.confidence&.to_f,
      created_at: item.created_at,
      updated_at: item.updated_at
    }
  end

  def receipt_adjustment_json(adjustment)
    {
      id: adjustment.id,
      receipt_id: adjustment.receipt_id,
      label: adjustment.label,
      kind: adjustment.kind,
      amount_cents: adjustment.amount_cents,
      included_in_total: adjustment.included_in_total,
      position: adjustment.position,
      created_at: adjustment.created_at,
      updated_at: adjustment.updated_at
    }
  end

  def bill_participant_json(participant)
    {
      id: participant.id,
      bill_id: participant.bill_id,
      name: participant.name,
      initials: participant.initials,
      avatar_background_color: participant.avatar_background_color,
      avatar_text_color: participant.avatar_text_color,
      seat_index: participant.seat_index,
      is_host: participant.is_host,
      settled: participant.settled,
      created_at: participant.created_at,
      updated_at: participant.updated_at
    }
  end

  def item_assignment_json(assignment)
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
