# frozen_string_literal: true

class Api::Mobile::V1::ReceiptItemsController < Api::Mobile::V1::BaseController
  def create
    bill = find_bill_for_current_user(params[:bill_id])
    return render_not_found("Bill not found") unless bill

    attributes = prepared_receipt_item_attributes(bill, receipt_item_params)
    item = bill.receipt_items.build(attributes)
    item.receipt = bill.receipt if bill.receipt

    if item.save
      return render_receipt_item_response(item, bill, status: :created)
    end

    render_validation_errors(item)
  end

  def update
    item = find_receipt_item_for_current_user
    return render_not_found("Receipt item not found") unless item

    attributes = prepared_receipt_item_attributes(item.bill, receipt_item_params, item: item)

    if item.update(attributes)
      return render_receipt_item_response(item, item.bill)
    end

    render_validation_errors(item)
  end

  def destroy
    item = find_receipt_item_for_current_user
    return render_not_found("Receipt item not found") unless item

    bill = item.bill
    item_json = receipt_item_payload(item)
    item.destroy!

    render json: {
      receipt_item: item_json,
      bill_summary: bill_summary_payload(bill)
    }
  end

  private

  def find_bill_for_current_user(bill_id)
    current_user.bills.find_by(id: bill_id)
  end

  def find_receipt_item_for_current_user
    ReceiptItem
      .joins(:bill)
      .where(bills: { user_id: current_user.id })
      .find_by(id: params[:id])
  end

  def receipt_item_params
    params.require(:receipt_item).permit(
      :name,
      :quantity,
      :unit_price_cents,
      :total_cents,
      :category,
      :icon_key,
      :position,
      :confidence
    )
  end

  def prepared_receipt_item_attributes(bill, permitted, item: nil)
    attributes = permitted.to_h

    quantity = attributes[:quantity].presence || item&.quantity || 1
    attributes[:quantity] = quantity

    if attributes[:total_cents].blank?
      unit_price_cents = attributes[:unit_price_cents].presence || item&.unit_price_cents
      if unit_price_cents.present?
        attributes[:total_cents] = (unit_price_cents.to_i * BigDecimal(quantity.to_s)).round
      end
    end

    if item.nil? && attributes[:position].blank?
      attributes[:position] = (bill.receipt_items.maximum(:position) || -1) + 1
    end

    attributes
  end

  def render_receipt_item_response(item, bill, status: :ok)
    render json: {
      receipt_item: receipt_item_payload(item),
      bill_summary: bill_summary_payload(bill)
    }, status: status
  end
end
