class ExchangeRate < ApplicationRecord
  belongs_to :country

  validates :country_id, presence: true
  validates :rate_used, presence: true
  validates :date, presence: true

  scope :latest, -> { order(date: :desc) }
  scope :by_country, ->(country_id) { where(country_id:) }
end
