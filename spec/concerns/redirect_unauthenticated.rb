# frozen_string_literal: true

require "rails_helper"

shared_examples_for "redirect_unauthenticated" do
  def path
    root_path
  end

  context "not logged in" do
    describe "GET /index" do
      it "should redirect to the login page" do
        get path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
