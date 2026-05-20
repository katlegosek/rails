# frozen_string_literal: true

require "rails_helper"

shared_examples_for "paginatable" do
  let(:path) {  raise "system/paginatable path method not provided" }
  let(:generate_enough_records) {  raise "system/paginatable generate_enough_records method not provided" }

  before do
    generate_enough_records
    visit path
  end

  it "should go to the next page", js: true do
    click_on "Next"
    expect(page).to have_current_path /page=2/
  end

  it "should go to the previous page", js: true do
    click_on "Next"
    click_on "Prev"
    expect(page).to have_current_path /page=1/
  end

  it "should go to page 2 and back to page 1", js: true do
    click_on "2"
    expect(page).to have_current_path /page=2/
    click_on "1"
    expect(page).to have_current_path /page=1/
  end
end
