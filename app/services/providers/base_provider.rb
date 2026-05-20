# frozen_string_literal: true

class Providers::BaseProvider
  attr_reader :type

  def initialize
    @type = "base"
  end

  def send(_message, _recipient, _options: {})
    raise NotImplementedError "Subclasses must implement the send method"
  end

  def can_send?(message, recipient)
    message.present? && recipient.present?
  end

  def self.type?
    new.type
  end

  private

  def format_mobile(mobile)
    mobile.sub(/^0/, "+27")
  end
end
