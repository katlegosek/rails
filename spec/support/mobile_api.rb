# frozen_string_literal: true

RSpec.shared_context "mobile api current user" do
  let!(:user) { create(:user) }

  before do
    allow(User).to receive(:first).and_return(user)
  end
end

RSpec.configure do |config|
  config.include_context "mobile api current user",
    file_path: %r{spec/requests/api/mobile/v1}
end
