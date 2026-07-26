# frozen_string_literal: true

class Api::Mobile::V1::ReceiptImagesController < Api::Mobile::V1::BaseController
  def create
    bill = find_bill_for_current_mobile_user
    return render_not_found("Bill not found") unless bill
    ensure_bill_mutable!(bill)

    unless uploaded_image_param.present?
      return render_bad_request(
        message: "Image is required.",
        details: { image: [ "can't be blank" ] }
      )
    end

    receipt = bill.receipt || bill.create_receipt!(status: :draft)
    receipt_image = receipt.receipt_images.build(receipt_image_attributes(receipt))
    receipt_image.image.attach(uploaded_image_param)

    unless receipt_image.save
      return render_validation_errors(receipt_image)
    end

    receipt.processing!
    processing_run = receipt.receipt_processing_runs.create!(
      provider: "fake_ocr",
      status: :pending
    )

    ProcessReceiptJob.perform_later(receipt.id)

    render json: {
      receipt: Api::Mobile::V1::ReceiptStatusSerializer.new(receipt).as_json,
      receipt_image: Api::Mobile::V1::ReceiptImageSerializer.new(receipt_image).as_json,
      processing_run: Api::Mobile::V1::ReceiptProcessingRunSerializer.new(processing_run).as_json
    }, status: :created
  end

  private

  def find_bill_for_current_mobile_user
    current_mobile_user.bills.find_by(id: params[:bill_id])
  end

  def uploaded_image_param
    params[:image]
  end

  def receipt_image_attributes(receipt)
    {
      position: next_image_position(receipt, params[:position]),
      capture_type: params[:capture_type].presence || "full"
    }
  end

  def next_image_position(receipt, requested_position)
    return requested_position.to_i if requested_position.present?

    (receipt.receipt_images.maximum(:position) || -1) + 1
  end
end
