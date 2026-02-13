class TelcoPlan < ApplicationRecord
  belongs_to :channel
  has_many :telco_device_prices, dependent: :destroy

  validates :plan_name, presence: true
  validates :channel_id, presence: true

  scope :active, -> { where(active: true) }
  scope :by_contract_months, ->(months) { where(contract_months: months) }
end
