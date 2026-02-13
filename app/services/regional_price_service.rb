# frozen_string_literal: true

# RegionalPrice Service - Cross-country price comparison
# Single Responsibility: Compare prices across countries vs base benchmark
# Vibe Coding: Extracted constants, no hardcoded values
class RegionalPriceService
  include DashboardConstants

  # Compare prices to base country (UAE benchmark)
  # @param base_country_id [Integer] Base country ID for comparison
  # @param country_ids [Array<Integer>] Optional specific countries to compare
  # @return [Hash] Regional comparison data
  def self.compare_to_base(base_country_id:, country_ids: nil)
    base_country = Country.find_by(id: base_country_id)
    raise ArgumentError, 'Base country not found' unless base_country

    countries_to_compare = country_ids ? Country.where(id: country_ids) : Country.active.where.not(id: base_country_id)

    # Get average prices by country
    country_prices = calculate_average_prices_by_country(base_country_id)

    # Calculate comparisons
    {
      base_country: base_country,
      comparisons: build_comparisons(country_prices, base_country),
      summary: calculate_summary(country_prices, base_country)
    }
  end

  # Calculate average prices by country
  # @param base_country_id [Integer] Include base country in calculations
  # @return [Hash] Country ID to average price mapping
  def self.calculate_average_prices_by_country(base_country_id)
    # Get recent prices from all countries
    recent_prices = Price.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                          .joins(:channel)
                          .group('channel.country_id')
                          .average(:price_usd)

    recent_prices.transform_keys { |country_id| Country.find_by(id: country_id)&.name || "Country ##{country_id}" }
  end

  private

  # Build comparison data for each country
  # @param country_prices [Hash] Average prices by country
  # @param base_country [Country] Base country object
  # @return [Array<Hash>] Comparison data
  def self.build_comparisons(country_prices, base_country)
    base_price = country_prices[base_country.name] || 0

    country_prices.map do |country_name, avg_price|
      next if country_name == base_country.name

      price_diff = avg_price - base_price
      price_percent = base_price.positive? ? ((price_diff / base_price) * 100).round(1) : 0

      {
        country: country_name,
        avg_price: avg_price&.round(2),
        price_diff: price_diff&.round(2),
        price_percent: price_percent,
        status: determine_status(price_percent)
      }
    end.compact
  end

  # Calculate summary statistics
  # @param country_prices [Hash] Average prices by country
  # @param base_country [Country] Base country object
  # @return [Hash] Summary data
  def self.calculate_summary(country_prices, base_country)
    base_price = country_prices[base_country.name] || 0

    prices = country_prices.values.compact
    return {} if prices.empty?

    {
      base_price: base_price&.round(2),
      highest: prices.max,
      lowest: prices.min,
      avg_price: (prices.sum / prices.length).round(2),
      country_count: country_prices.length
    }
  end

  # Determine status based on price difference
  # @param price_percent [Float] Price difference percentage
  # @return [String] Status label
  def self.determine_status(price_percent)
    case price_percent
    when 100..Float::INFINITY then 'critical'
    when 20..99 then 'warning'
    when -20..-1 then 'cheaper'
    else 'normal'
    end
  end
end
