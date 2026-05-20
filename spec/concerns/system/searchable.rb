# frozen_string_literal: true

require "rails_helper"

shared_examples_for "searchable" do |field_name: "Search"|
  let(:path) {  raise "system/searchable path method not provided" }
  let(:search_content) {  raise "system/searchable search_content method not provided" }

  before do
    visit path
    fill_in field_name, with: search_content
  end

  it "should only show that record", js: true do
    expect(page).to have_text "Showing 1 - 1 of 1"
    expect(page).to have_text search_content
  end

  it "should empty the filters", js: true do
    click_on "Clear"
    expect(find_field(field_name).value).to eq("")
  end
end
