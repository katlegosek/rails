# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bill, type: :model do
  describe "#ensure_share_token!" do
    it "generates a unique URL-safe token once" do
      first_bill = create(:bill)
      second_bill = create(:bill)

      first_token = first_bill.ensure_share_token!
      second_token = second_bill.ensure_share_token!

      expect(first_token).to be_present
      expect(second_token).to be_present
      expect(first_token).not_to eq(second_token)
      expect(first_bill.ensure_share_token!).to eq(first_token)
    end
  end
end
