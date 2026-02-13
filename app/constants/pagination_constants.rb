# frozen_string_literal: true

# Pagination-related constants
module PaginationConstants
  # Default number of items per page
  DEFAULT_PAGE_LIMIT = 100

  # Maximum number of items per page (to prevent excessive queries)
  MAX_PAGE_LIMIT = 1000

  # Default page number
  DEFAULT_PAGE = 1
end
