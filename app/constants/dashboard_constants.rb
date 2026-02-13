# frozen_string_literal: true

# Dashboard Constants - Vibe Coding Principle: No Hardcoding
# All magic numbers and strings extracted as named constants

module DashboardConstants
  # Time Ranges
  DEFAULT_TIME_RANGE_DAYS = 30
  PRICE_TREND_DAYS = 30

  # Thresholds
  CRITICAL_DISCOUNT_THRESHOLD = 30  # percent below UAE benchmark
  WARNING_DISCOUNT_THRESHOLD = 20   # percent below UAE benchmark
  SIGNIFICANT_PRICE_CHANGE = 10     # percent change
  BEST_VALUE_THRESHOLD = 20         # percent below average

  # Pagination
  DEFAULT_PAGE_SIZE = 20
  MAX_PAGE_SIZE = 100

  # Cache Expiration (seconds)
  STATS_CACHE_EXPIRATION = 12.hours
  MARKET_SHARE_CACHE_EXPIRATION = 1.hour

  # Status Labels
  STATUS_NORMAL = 'normal'
  STATUS_WARNING = 'warning'
  STATUS_CRITICAL = 'critical'

  # Chart Settings
  MAX_CHART_DATA_POINTS = 1000
  CHART_ANIMATION_DURATION = 750

  # Search
  MIN_SEARCH_QUERY_LENGTH = 2
  DEFAULT_SEARCH_LIMIT = 10
  MAX_SEARCH_LIMIT = 50

  # Competition - Market Position (USD)
  MARKET_POSITION_PREMIUM_THRESHOLD = 1000
  MARKET_POSITION_MIDRANGE_THRESHOLD = 600

  # Competition - Competitor Price Range (multipliers)
  COMPETITOR_PRICE_RANGE_MIN = 0.8
  COMPETITOR_PRICE_RANGE_MAX = 1.2

  # Competition - Display Limits
  NEW_ENTRIES_DISPLAY_LIMIT = 10
  COMPARISON_MIN_PHONES = 2
  COMPARISON_MAX_PHONES = 4

  # Regional - Base Country
  DEFAULT_BASE_COUNTRY_ID = 1  # UAE as default benchmark
end
