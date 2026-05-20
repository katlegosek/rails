# frozen_string_literal: true

class Atoms::Pagination::Component < ApplicationViewComponent
  with_collection_parameter :pagination

  option :resources

  def before_render
    @total_pages = resources.total_pages
    @current_page = resources.current_page
    visible_pages = 5

    if @total_pages <= visible_pages
      @start_page = 1
      @end_page = @total_pages
    elsif @current_page <= (visible_pages / 2.0).ceil
      @start_page = 1
      @end_page = visible_pages
    elsif @current_page >= (@total_pages - (visible_pages / 2.0).floor)
      @start_page = @total_pages - visible_pages + 1
      @end_page = @total_pages
    else
      @start_page = @current_page - (visible_pages / 2.0).floor
      @end_page = @current_page + (visible_pages / 3.0).floor
    end

    @end_page -= 1 if @start_page == 1 && @total_pages > 5
  end

  attr_reader :total_pages, :current_page, :start_page, :end_page
end
