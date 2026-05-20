# frozen_string_literal: true

module FlashHelper
  def flash_notify
    flash_messages = []
    flash.each do |type, message|
      next if message.blank?

      if type.to_sym == :notice
        type_class = "text-green-800 border border-green-300 rounded-lg bg-green-50 dark:bg-gray-800 dark:text-green-400 dark:border-green-800"
      elsif type.to_sym == :alert
        type_class = "text-red-800 border border-red-300 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400 dark:border-red-800"
      end

      Array(message).each do |msg|
        next unless msg.is_a? String

        text = content_tag(:div, msg.to_s.html_safe, class: class_names("flex items-center p-4 mb-4 text-sm", type_class))
        flash_messages << text if msg
      end
    end
    flash_messages.join("\n").html_safe
  end
end
