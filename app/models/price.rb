# frozen_string_literal: true

class Price < ApplicationRecord
  belongs_to :phone
  belongs_to :channel
  has_one :telco_device_price, dependent: :destroy

  validates :channel_id, presence: true
  validates :date, presence: true

  # Price types defined in constants
  enum :price_type, {
    nominal: PriceConstants::NOMINAL,
    telco_contract: PriceConstants::TELCO_CONTRACT,
    promotion: PriceConstants::PROMOTION,
    bundle: PriceConstants::BUNDLE,
    manual: PriceConstants::MANUAL
  }

  # Stock status defined in constants
  enum :stock_status, {
    in_stock: PriceConstants::IN_STOCK,
    out_of_stock: PriceConstants::OUT_OF_STOCK,
    preorder: PriceConstants::PREORDER
  }

  scope :recent, -> { order(date: :desc) }
  scope :by_phone, ->(phone_id) { where(phone_id:) }
  scope :by_channel, ->(channel_id) { where(channel_id:) }
end
