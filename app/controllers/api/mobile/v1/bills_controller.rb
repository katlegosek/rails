# frozen_string_literal: true

class Api::Mobile::V1::BillsController < Api::Mobile::V1::BaseController
  def index
    bills = current_mobile_user.bills
      .includes(:bill_participants, receipt: :receipt_processing_runs)
      .order(created_at: :desc)

    render json: { bills: Api::Mobile::V1::BillListItemSerializer.collection(bills) }
  end

  def create
    bill = current_mobile_user.bills.create!(
      status: :draft,
      title: bill_create_title
    )

    render json: { bill: Api::Mobile::V1::BillResourceSerializer.new(bill).as_json }, status: :created
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

    render json: Api::Mobile::V1::BillSerializer.new(bill).as_json
  end

  def summary
    bill = find_bill_for_room

    return render_not_found("Bill not found") unless bill

    render json: Api::Mobile::V1::BillSummarySerializer.new(bill).as_json
  end

  def confirm
    bill = find_bill_for_room
    return render_not_found("Bill not found") unless bill

    if bill.receipt && !bill.receipt.ready? && !bill.receipt.confirmed?
      return render_validation_details(
        { receipt: [ "must be ready before the bill room can be opened" ] },
        message: "This receipt is not ready to confirm yet."
      )
    end

    Bill.transaction do
      bill.receipt&.confirmed! unless bill.receipt&.confirmed?
      bill.ensure_share_token!
      ensure_host_participant!(bill)
      bill.update!(
        session_status: :open,
        status: :active,
        confirmed_at: bill.confirmed_at || Time.current
      )
    end

    render json: Api::Mobile::V1::BillRoomSerializer.new(bill.reload).as_json
  end

  def room
    bill = find_bill_for_room
    return render_not_found("Bill not found") unless bill

    render json: Api::Mobile::V1::BillRoomSerializer.new(bill).as_json
  end

  def finalize
    bill = find_bill_for_room
    return render_not_found("Bill not found") unless bill

    bill.update!(
      session_status: :finalized,
      status: :completed,
      finalized_at: bill.finalized_at || Time.current
    )

    render json: Api::Mobile::V1::BillRoomSerializer.new(bill.reload).as_json
  end

  private

  def find_bill_for_room
    current_mobile_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: %i[receipt_adjustments receipt_processing_runs],
        receipt_items: :item_assignments,
        bill_participants: :item_assignments
      )
      .find_by(id: params[:id])
  end

  def ensure_host_participant!(bill)
    host = bill.bill_participants.find_or_initialize_by(is_host: true)
    return if host.persisted?

    host.assign_attributes(
      name: current_mobile_user.full_name,
      initials: [ current_mobile_user.first_name, current_mobile_user.last_name ].filter_map(&:first).join.upcase,
      seat_index: bill.bill_participants.maximum(:seat_index).to_i + 1
    )
    host.save!
  end

  def bill_create_title
    params.dig(:bill, :title).presence || "New bill"
  end
end
