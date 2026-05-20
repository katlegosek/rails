# frozen_string_literal: true

class Messages::BaseMessage
  def self.format(message)
    case ENV.fetch("RAILS_ENV")
    when "development"
      "Development\n\n#{message}"
    when "staging"
      "Staging\n\n#{message}"
    else
      message
    end
  end
end
