# frozen_string_literal: true

# Price-related constants
module PriceConstants
  # Price type enum values
  NOMINAL = 'nominal'
  TELCO_CONTRACT = 'telco_contract'
  PROMOTION = 'promotion'
  BUNDLE = 'bundle'
  MANUAL = 'manual'

  # All available price types
  PRICE_TYPES = [
    NOMINAL,
    TELCO_CONTRACT,
    PROMOTION,
    BUNDLE,
    MANUAL
  ].freeze

  # Stock status enum values
  IN_STOCK = 'in_stock'
  OUT_OF_STOCK = 'out_of_stock'
  PREORDER = 'preorder'

  # All available stock statuses
  STOCK_STATUSES = [
    IN_STOCK,
    OUT_OF_STOCK,
    PREORDER
  ].freeze
end
