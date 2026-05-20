# frozen_string_literal: true

class Atoms::Icons::Component < ApplicationViewComponent
  option :type
  option :class_names, optional: true, default: proc { nil }
end
