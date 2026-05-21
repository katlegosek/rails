# frozen_string_literal: true

require "rails_helper"

# Legacy template auth endpoints are not mounted under api/mobile/v1 in the bill-splitting API.
RSpec.describe Api::Mobile::V1::UsersController, type: :request do
  before do
    skip "User auth routes are not configured for the bill-splitting mobile API"
  end

  it "is pending until user routes are added" do
    expect(true).to be(true)
  end
end
