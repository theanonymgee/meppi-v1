# frozen_string_literal: true

class TelcoDevicePrice < ApplicationRecord
  belongs_to :price
  belongs_to :telco_plan

  validates :price_id, presence: true
  validates :telco_plan_id, presence: true

  # Calculate total effective cost
  def total_effective_cost
    (device_price_local || 0) + ((monthly_installment || 0) * ContractConstants::DEFAULT_MONTHS)
  end
end
