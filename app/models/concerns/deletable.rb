# frozen_string_literal: true

module Deletable
  extend ActiveSupport::Concern

  included do
    scope :not_deleted, -> { where(deleted_at: nil) }

    scope :deleted, -> { where.not(deleted_at: nil) }

    scope :archived, lambda { |is_archived = true|
                       [ true, 1, "true", "1" ].include?(is_archived) ? deleted : not_deleted
                     }

    def archive
      update(deleted_at: Time.zone.now)
    end

    def restore
      update(deleted_at: nil)
    end
  end
end
