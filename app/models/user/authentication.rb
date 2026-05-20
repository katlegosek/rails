# frozen_string_literal: true

module User::Authentication
  extend ActiveSupport::Concern

  included do
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable,
           :confirmable, :lockable, :timeoutable, :trackable

    def active_for_authentication?
      super && role_allows_login?
    end

    def inactive_message
      return :role_not_allowed unless role_allows_login?

      super
    end

    def send_confirmation_notification?
      admin?
    end

    private

    def role_allows_login?
      admin?
    end
  end
end
