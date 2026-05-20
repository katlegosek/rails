# frozen_string_literal: true

module BillAssignments
  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.to_json)
    end
  end
end
