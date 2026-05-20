# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Mobile::V1::ReceiptImages", type: :request do
  include ActiveJob::TestHelper

  before do
    ActiveStorage::Current.url_options = { host: "www.example.com", protocol: "https" }
    Rails.application.routes.default_url_options[:host] = "www.example.com"
  end

  describe "POST /api/mobile/v1/bills/:bill_id/receipt_images" do
    let(:bill) { create(:bill, user: user) }

    it "uploads an image, enqueues processing, and returns processing state" do
      expect {
        post "/api/mobile/v1/bills/#{bill.id}/receipt_images", params: {
          image: receipt_image_upload,
          capture_type: "full"
        }
      }.to have_enqueued_job(ProcessReceiptJob)

      expect(response).to have_http_status(:created)
      body = response.parsed_body

      expect(body["receipt"]).to include("status" => "processing")
      expect(body["receipt_image"]).to include("capture_type" => "full")
      expect(body["processing_run"]).to include("provider" => "fake_ocr", "status" => "pending")

      receipt = Receipt.find(body["receipt"]["id"])
      expect(receipt).to be_processing
      expect(receipt.receipt_images.count).to eq(1)
    end

    it "creates a receipt when the bill does not have one yet" do
      expect(bill.receipt).to be_nil

      post "/api/mobile/v1/bills/#{bill.id}/receipt_images", params: {
        image: receipt_image_upload
      }

      expect(response).to have_http_status(:created)
      expect(bill.reload.receipt).to be_present
    end

    it "returns validation errors when the image is missing" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_images", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(api_error(response.parsed_body)["code"]).to eq("bad_request")
      expect(api_error(response.parsed_body)["details"]["image"]).to include("can't be blank")
    end

    it "returns not found for another user's bill" do
      other_bill = create(:bill, user: create(:user))

      post "/api/mobile/v1/bills/#{other_bill.id}/receipt_images", params: {
        image: receipt_image_upload
      }

      expect(response).to have_http_status(:not_found)
      expect(api_error(response.parsed_body)).to include("code" => "not_found", "message" => "Bill not found")
    end

    it "completes fake OCR processing via the background job" do
      post "/api/mobile/v1/bills/#{bill.id}/receipt_images", params: {
        image: receipt_image_upload
      }

      receipt_id = response.parsed_body["receipt"]["id"]
      perform_enqueued_jobs

      receipt = Receipt.find(receipt_id)
      expect(receipt).to be_ready
      expect(receipt.receipt_items.count).to be_between(6, 8)
    end
  end
end
