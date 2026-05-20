# frozen_string_literal: true

class Atoms::Breadcrumbs::Component < ApplicationViewComponent
  with_collection_parameter :breadcrumbs

  option :additional, optional: true, default: proc { [] }

  def before_render
    pre_breadcrumbs = request.path.split("/").reject(&:empty?)

    @route_crumbs = pre_breadcrumbs.map.with_index do |breadcrumb, _index|
      Integer(breadcrumb)
    rescue StandardError
      breadcrumb
    end.compact
  end

  attr_reader :route_crumbs
end
