class Promotion < ApplicationRecord
  belongs_to :channel
  belongs_to :phone, optional: true

  validates :channel_id, presence: true
  validate :valid_date_range

  scope :active, -> { where('valid_from <= ? AND valid_until >= ?', Date.today, Date.today) }
  scope :upcoming, -> { where('valid_from > ?', Date.today) }

  private

  def valid_date_range
    return if valid_from.blank? || valid_until.blank?

    return unless valid_until < valid_from

    errors.add(:valid_until, 'must be after valid_from')
  end
end
