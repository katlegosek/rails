# frozen_string_literal: true

class Api::Mobile::V1::ReceiptAdjustmentsController < Api::Mobile::V1::BaseController
  def create
    receipt = find_receipt_for_current_user
    return render_not_found("Receipt not found") unless receipt

    adjustment = receipt.receipt_adjustments.build(adjustment_attributes_for_create(receipt))

    if adjustment.save
      return render_adjustment_response(adjustment, receipt.bill, status: :created)
    end

    render_validation_errors(adjustment)
  end

  def update
    adjustment = find_adjustment_for_current_user
    return render_not_found("Receipt adjustment not found") unless adjustment

    if adjustment.update(adjustment_params)
      return render_adjustment_response(adjustment, adjustment.receipt.bill)
    end

    render_validation_errors(adjustment)
  end

  def destroy
    adjustment = find_adjustment_for_current_user
    return render_not_found("Receipt adjustment not found") unless adjustment

    bill = adjustment.receipt.bill
    adjustment_json = receipt_adjustment_payload(adjustment)
    adjustment.destroy!

    render json: {
      receipt_adjustment: adjustment_json,
      bill_summary: bill_summary_payload(bill)
    }
  end

  private

  def find_receipt_for_current_user
    Receipt
      .joins(:bill)
      .where(bills: { user_id: current_user.id })
      .find_by(id: params[:receipt_id])
  end

  def find_adjustment_for_current_user
    ReceiptAdjustment
      .joins(receipt: :bill)
      .where(bills: { user_id: current_user.id })
      .find_by(id: params[:id])
  end

  def adjustment_params
    params.require(:receipt_adjustment).permit(
      :label,
      :kind,
      :amount_cents,
      :affects_total,
      :position
    )
  end

  def adjustment_attributes_for_create(receipt)
    attributes = adjustment_params.to_h

    unless receipt_adjustment_key?(:affects_total)
      attributes[:affects_total] = false
    end

    if attributes[:position].blank?
      attributes[:position] = (receipt.receipt_adjustments.maximum(:position) || -1) + 1
    end

    attributes
  end

  def receipt_adjustment_key?(key)
    source = params[:receipt_adjustment]
    source.key?(key) || source.key?(key.to_s)
  end

  def render_adjustment_response(adjustment, bill, status: :ok)
    render json: {
      receipt_adjustment: receipt_adjustment_payload(adjustment),
      bill_summary: bill_summary_payload(bill)
    }, status: status
  end
end
