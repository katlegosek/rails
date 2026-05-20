# frozen_string_literal: true

class Api::Mobile::V1::ReceiptImagesController < Api::Mobile::V1::BaseController
  include Rails.application.routes.url_helpers

  def create
    bill = find_bill_for_current_user
    return render_not_found unless bill

    unless uploaded_image_param.present?
      return render json: { errors: { image: [ "can't be blank" ] } }, status: :unprocessable_content
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
      receipt: {
        id: receipt.id,
        status: receipt.status
      },
      receipt_image: receipt_image_payload(receipt_image),
      processing_run: processing_run_payload(processing_run)
    }, status: :created
  end

  private

  def find_bill_for_current_user
    current_user.bills.find_by(id: params[:bill_id])
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

  def receipt_image_payload(receipt_image)
    {
      id: receipt_image.id,
      receipt_id: receipt_image.receipt_id,
      position: receipt_image.position,
      capture_type: receipt_image.capture_type,
      image_url: receipt_image.image.attached? ? url_for(receipt_image.image) : nil,
      created_at: receipt_image.created_at,
      updated_at: receipt_image.updated_at
    }
  end

  def processing_run_payload(processing_run)
    {
      id: processing_run.id,
      receipt_id: processing_run.receipt_id,
      provider: processing_run.provider,
      status: processing_run.status,
      started_at: processing_run.started_at,
      completed_at: processing_run.completed_at,
      created_at: processing_run.created_at,
      updated_at: processing_run.updated_at
    }
  end
end
