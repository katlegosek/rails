# frozen_string_literal: true

require "rails_helper"
require Rails.root.join "spec/concerns/redirect_unauthenticated.rb"

RSpec.describe DashboardsController, type: :request do
  it_behaves_like "redirect_unauthenticated"

  context "logged in" do
    before(:each) do
      authenticate_administrator
    end

    describe "GET /index" do
      it "should render index page" do
        get root_path
        expect(response).to render_template :index
      end
    end
  end
end
