# frozen_string_literal: true

# Service for calculating dashboard statistics
# Extracts business logic from controllers
class StatsService
  # Get summary statistics for the dashboard
  # @return [Hash] Dashboard statistics including phone/price/country counts
  def self.summary
    {
      total_phones: Phone.count,
      total_prices: Price.count,
      total_countries: Country.count,
      total_channels: Channel.count,
      latest_price_date: Price.maximum(:date),
      brands: Phone.select(:brand).distinct.count
    }
  end
end
