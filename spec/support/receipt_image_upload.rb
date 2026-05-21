# frozen_string_literal: true

module ReceiptImageUpload
  FIXTURE_PATH = Rails.root.join("spec/fixtures/files/receipt.jpg").freeze

  def receipt_image_upload(content_type: "image/jpeg")
    Rack::Test::UploadedFile.new(FIXTURE_PATH, content_type)
  end
end

RSpec.configure do |config|
  config.include ReceiptImageUpload, type: :request
end
