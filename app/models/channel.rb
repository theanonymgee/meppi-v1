# frozen_string_literal: true

class Channel < ApplicationRecord
  self.primary_key = :id

  # Associations
  belongs_to :country
  has_many :prices, dependent: :destroy
  has_many :telco_plans, dependent: :destroy
  has_many :promotions, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :channel_type, presence: true
  validates :country_id, presence: true

  # Enumerations
  enum channel_type: {
    telco: ChannelConstants::TELCO,
    retail: ChannelConstants::RETAIL,
    pure_player: ChannelConstants::PURE_PLAYER,
    hypermarket: ChannelConstants::HYPERMARKET,
    brand_official: ChannelConstants::BRAND_OFFICIAL,
    official_brand: ChannelConstants::OFFICIAL_BRAND
  }

  scope :active, -> { where(active: true) }
end
