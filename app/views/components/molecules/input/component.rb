# frozen_string_literal: true

class Molecules::Input::Component < BaseFormComponent
  with_collection_parameter :input

  option :field_type, optional: true, default: proc { "text_field" }

  renders_one :left_icon
  renders_one :helper_text

  style do
    base { "border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary focus-visible:outline-primary focus:border-primary block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary dark:focus:border-primary disabled:cursor-not-allowed disabled:text-gray-400" }
    variants {
      icon {
        yes { "ps-9" }
        no { "" }
      }
    }
  end
end
