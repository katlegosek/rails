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

    render json: Api::Mobile::V1::BillSummarySerializer.new(bill).as_json
  end

  private

  def bill_create_title
    params.dig(:bill, :title).presence || "New bill"
  end
end
