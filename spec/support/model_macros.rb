# frozen_string_literal: true

module ModelMacros
  def authenticate_user
    @application = FactoryBot.create(:doorkeeper_application)
  end

  def valid_user_attributes(email = "user@fetza.test")
    {
      email:,
      password: 'Password1!',
      first_name: 'Test',
      last_name: 'User'
    }
  end
end
