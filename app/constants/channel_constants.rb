# frozen_string_literal: true

# Channel-related constants
module ChannelConstants
  # Channel type enum values
  TELCO = 'telco'
  RETAIL = 'retail'
  PURE_PLAYER = 'pure_player'
  HYPERMARKET = 'hypermarket'
  BRAND_OFFICIAL = 'brand_official'
  OFFICIAL_BRAND = 'official_brand'

  # All available channel types
  CHANNEL_TYPES = [
    TELCO,
    RETAIL,
    PURE_PLAYER,
    HYPERMARKET,
    BRAND_OFFICIAL,
    OFFICIAL_BRAND
  ].freeze

  # Channel type priority (lower = higher priority)
  CHANNEL_PRIORITY = {
    TELCO => 1,
    OFFICIAL_BRAND => 2,
    RETAIL => 3,
    PURE_PLAYER => 4,
    HYPERMARKET => 5,
    BRAND_OFFICIAL => 6
  }.freeze
end
