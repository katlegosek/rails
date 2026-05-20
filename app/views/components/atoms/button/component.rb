# frozen_string_literal: true

class Atoms::Button::Component < ApplicationViewComponent
  option :title, optional: true
  option :id, optional: true
  option :as, optional: true, default: proc { :button_tag }
  option :path, optional: true
  option :data, optional: true, default: proc { {} }
  option :class_names, optional: true
  option :form, optional: true
  option :name, optional: true, default: proc { nil }
  option :type, optional: true, default: proc { "button" }

  option :variant, optional: true, default: proc { :container }
  option :state, optional: true, default: proc { :default }

  style do
    base { "" }
    variants {
      variant {
        container { "text-white bg-primary hover:bg-primary/80 focus:ring-4 focus:ring-primary/20 font-medium rounded-lg text-sm px-5 py-2.5" }
        outline { "text-primary hover:text-white border border-primary hover:bg-primary focus:ring-4 focus:outline-none focus:ring-primary/20 font-medium rounded-lg text-sm px-5 py-2 text-center dark:hover:text-white" }
        link { "text-primary underline-offset-4 hover:underline active:text-primary/60 disabled:text-gray-300 disabled:no-underline" }
        text { "text-primary active:text-primary/60 disabled:text-gray-300" }
        icon { "text-black hover:bg-primary/10 hover:text-primary focus:ring-4 focus:outline-none focus:ring-primary/20 font-medium rounded-lg text-sm p-2 text-center inline-flex items-center dark:hover:text-white" }
      }
      state {
        default { "" }
        disabled { "" }
      }
    }
  end
end
