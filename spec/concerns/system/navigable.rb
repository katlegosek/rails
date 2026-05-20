# frozen_string_literal: true

require "rails_helper"

shared_examples_for "navigable" do
  let(:path) {  raise "system/navigable path method not provided" }
  let(:action) { raise "system/navigable action method not provided" }
  let(:destination_path) { raise "system/navigable destination_path method not provided" }

  before do
    visit path
    action
  end

  it "performs the action and navigates to the new page", js: true do
    expect(page).to have_current_path(destination_path)
  end
end
