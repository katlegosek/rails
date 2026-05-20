# frozen_string_literal: true

module SystemMacros
  def authenticate_admin
    @admin = FactoryBot.create(:user, role: :admin)
    sign_in @admin
  end
end
