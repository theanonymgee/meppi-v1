# frozen_string_literal: true

class Country < ApplicationRecord
  # Validations
  validates :code, presence: true
  validates :name, presence: true
  validates :currency, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
end
