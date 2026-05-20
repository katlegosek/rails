# frozen_string_literal: true

class Atoms::Label::Component < BaseFormComponent
  with_collection_parameter :label

  style do
    base { "block text-sm font-medium text-gray-900 dark:text-white" }
  end

  private

  def required?
    required
  end
end
