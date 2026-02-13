# frozen_string_literal: true

class MeppiTrade < ApplicationRecord
  # MEPPI 거래 내역
  self.primary_key = :id

  # Associations
  belongs_to :phone, optional: true
  belongs_to :channel, optional: true
  belongs_to :country, optional: true

  # Validations
  validates :title, presence: true
  validates :price_local, presence: true
  validates :currency, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Compact old records (delete trades older than 30 days)
  def self.compact
    where('created_at < ?', 30.days.ago).delete_all
  end
end
