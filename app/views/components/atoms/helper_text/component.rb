# frozen_string_literal: true

class Atoms::HelperText::Component < BaseFormComponent
  with_collection_parameter :helper_Text

  style do
    base { "mt-2 text-sm" }
    variants do
      color {
        default { "text-gray-500 dark:text-gray-400" }
        error { "text-red-500 dark:text-red-500" }
      }
    end
  end

  def render?
    content.nil?
  end
end
