# frozen_string_literal: true

require "rails_helper"
require Rails.root.join "spec/concerns/system/searchable.rb"
require Rails.root.join "spec/concerns/system/paginatable.rb"
require Rails.root.join "spec/concerns/system/navigable.rb"

RSpec.describe "Users", type: :system do
  before(:each) do
    authenticate_admin
  end

  it_behaves_like "searchable" do
    let(:path) { users_path }
    let(:search_content) { @admin.first_name }
  end

  it_behaves_like "paginatable" do
    let(:path) { users_path }
    let(:generate_enough_records) do
      10.times do
        FactoryBot.create(:user)
      end
    end
  end

  it_behaves_like "navigable" do
    let(:path) { users_path }
    let(:action) do
      find("#view-user-#{@admin.id}").click
    end
    let(:destination_path) { user_path(@admin.id) }
  end

  it_behaves_like "navigable" do
    let(:path) { users_path }
    let(:action) do
      find("#edit-user-#{@admin.id}").click
    end
    let(:destination_path) { edit_user_path(@admin.id) }
  end
end
