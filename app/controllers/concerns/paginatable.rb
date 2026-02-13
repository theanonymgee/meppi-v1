# frozen_string_literal: true

# Pagination concern for API controllers
# Provides reusable pagination methods
module Paginatable
  extend ActiveSupport::Concern

  # Get current page number from params
  # @return [Integer] Current page (defaults to 1)
  def page_param
    (params[:page] || PaginationConstants::DEFAULT_PAGE).to_i
  end

  # Get number of items per page from params
  # @return [Integer] Items per page (capped at MAX_PAGE_LIMIT)
  def per_page_param
    [
      (params[:per_page] || PaginationConstants::DEFAULT_PAGE_LIMIT).to_i,
      PaginationConstants::MAX_PAGE_LIMIT
    ].min
  end

  # Calculate offset for pagination
  # @return [Integer] Offset for SQL query
  def offset_param
    (page_param - 1) * per_page_param
  end
end
