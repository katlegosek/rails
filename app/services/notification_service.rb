# frozen_string_literal: true

class NotificationService
  def initialize
    @providers = [
      Provider::AatProvider,
      Providers::ClickatellProvider
    ]
  end

  def types
    @providers.map(&:type)
  end

  def self.send_for_all(message, recipient, options: {})
    service = new
    service.types.each do |type|
      service.send(type, message, recipient, options:)
    end
  end

  def self.send_for_some(types = [], message, recipient, options: {})
    service = new
    types.each do |type|
      service.send(type, message, recipient, options:)
    end
  end

  def self.send_for_one(type, message, recipient, options: {})
    service = new
    service.send(type, message, recipient, options:)
  end

  def send(type, message, recipient, options: {})
    provider = provider(type)
    provider.send(message, recipient, options:) if provider.present? && provider.can_send?(params)
  end

  def provider(type)
    providers = @providers.select do |provider|
      provider.type == type
    end
    providers.first if providers.length.positive?
  end
end
