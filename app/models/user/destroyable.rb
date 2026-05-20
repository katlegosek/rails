# frozen_string_literal: true

module User::Destroyable
  extend ActiveSupport::Concern

  included do
    after_update_commit :remove_access, if: :saved_change_to_deleted_at?

    def destroy
      skip_confirmation_notification!

      self.deleted_at = Time.zone.now
      self.email = "#{SecureRandom.hex(10)}@obfuscate.com"
      self.first_name = SecureRandom.hex(8)
      self.last_name = SecureRandom.hex(8)

      save
      confirm
    end

    def remove_access
      active_tokens = Doorkeeper::AccessToken.by_resource_owner(self)
                                             .where(revoked_at: nil)

      active_tokens.each do |token|
        application_id = token.application_id

        Doorkeeper::AccessToken.revoke_all_for(application_id, self)
      end
    end
  end
end
