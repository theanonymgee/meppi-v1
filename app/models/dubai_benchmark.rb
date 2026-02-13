class DubaiBenchmark < ApplicationRecord
  belongs_to :phone

  validates :phone_id, presence: true
  validates :price_aed, presence: true
  validates :date, presence: true

  scope :latest, -> { order(date: :desc) }
end
