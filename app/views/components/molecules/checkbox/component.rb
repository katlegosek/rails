# frozen_string_literal: true

class Molecules::Checkbox::Component < BaseFormComponent
  with_collection_parameter :checkbox

  style do
    base { "w-4 h-4 border border-gray-300 rounded-sm bg-gray-50 focus:ring-3 focus:ring-primary dark:bg-gray-700 dark:border-gray-600 dark:focus:ring-primary dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800 text-primary text-nowrap" }
  end
end
