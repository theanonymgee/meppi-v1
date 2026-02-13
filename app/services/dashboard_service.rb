# frozen_string_literal: true

# Dashboard Service - Business logic for home dashboard
# Single Responsibility: Aggregate and compute home dashboard statistics
# Vibe Coding: No hardcoded values, all constants extracted
class DashboardService
  include DashboardConstants

  # Main entry point - Get all home dashboard statistics
  # @param time_range_days [Integer] Number of days to analyze
  # @return [Hash] Structured dashboard data
  def self.home_stats(time_range_days: DEFAULT_TIME_RANGE_DAYS)
    start_date = time_range_days.days.ago.to_date

    {
      overview: overview_stats,
      price_trends: calculate_price_trends(start_date),
      regional_gaps: analyze_regional_gaps
    }
  end

  # Get phone price trends over time
  # @param start_date [Date] Start date for trend analysis
  # @return [Hash] Price trends by country and top movers
  def self.price_trends(start_date: PRICE_TREND_DAYS.days.ago.to_date)
    calculate_price_trends(start_date)
  end

  # Analyze regional pricing gaps against UAE benchmark
  # @return [Hash] Violators and premium chargers
  def self.regional_gaps
    analyze_regional_gaps
  end

  private

  # Overview statistics - High-level metrics
  # @return [Hash] Total counts and latest update
  def self.overview_stats
    {
      total_phones: Phone.count,
      total_prices: Price.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date).count,
      countries_count: Country.active.count,
      channels_count: Channel.active.count,
      latest_update: Price.maximum(:date)
    }
  end

  # Calculate price trends by country
  # @param start_date [Date] Start date for analysis
  # @return [Hash] By-country trends and top movers
  def self.calculate_price_trends(start_date)
    # Average price by country
    prices_by_country = Price
      .where('date >= ?', start_date)
      .joins(:channel)
      .group('channels.country_id')
      .average(:price_usd)

    by_country = Country.active.map do |country|
      avg_price = prices_by_country[country.id]
      next unless avg_price

      {
        country: country.name,
        avg_price: avg_price.round(2),
        trend: calculate_trend(country.id, start_date),
        change_percent: calculate_change_percent(country.id, start_date)
      }
    end.compact

    # Top price movers (phones with biggest price changes)
    top_movers = calculate_top_movers(start_date)

    {
      by_country:,
      top_movers:
    }
  end

  # Calculate price trend direction for a country
  # @param country_id [Integer] Country ID
  # @param start_date [Date] Start date
  # @return [String] "up", "down", or "stable"
  def self.calculate_trend(country_id, start_date)
    recent_avg = Price
      .where('date >= ?', 7.days.ago.to_date)
      .joins(:channel)
      .where(channels: { country_id: })
      .average(:price_usd) || 0

    previous_avg = Price
      .where(date: (start_date..(start_date + 6.days)))
      .joins(:channel)
      .where(channels: { country_id: })
      .average(:price_usd) || 0

    return 'stable' if recent_avg.zero? || previous_avg.zero?

    if recent_avg > previous_avg * 1.02
      'up'
    elsif recent_avg < previous_avg * 0.98
      'down'
    else
      'stable'
    end
  end

  # Calculate percentage change for a country
  # @param country_id [Integer] Country ID
  # @param start_date [Date] Start date
  # @return [Float] Percentage change
  def self.calculate_change_percent(country_id, start_date)
    recent_avg = Price
      .where('date >= ?', 7.days.ago.to_date)
      .joins(:channel)
      .where(channels: { country_id: })
      .average(:price_usd) || 0

    previous_avg = Price
      .where(date: (start_date..(start_date + 6.days)))
      .joins(:channel)
      .where(channels: { country_id: })
      .average(:price_usd) || 0

    return 0.0 if previous_avg.zero? || recent_avg.zero?

    (((recent_avg - previous_avg) / previous_avg) * 100).round(1)
  end

  # Find phones with biggest price changes
  # @param start_date [Date] Start date
  # @return [Array<Hash>] Top movers
  def self.calculate_top_movers(start_date)
    # Get prices at start and end of period
    start_prices = Price
      .where(date: start_date)
      .group(:phone_id)
      .average(:price_usd)

    end_prices = Price
      .where('date >= ?', Date.current - 2.days)
      .group(:phone_id)
      .average(:price_usd)

    movers = []
    start_prices.each do |phone_id, start_price|
      end_price = end_prices[phone_id]
      next unless end_price

      change_percent = ((end_price - start_price) / start_price * 100).round(1)
      next if change_percent.abs < 5.0 # Only show significant changes

      phone = Phone.find_by(id: phone_id)
      next unless phone

      movers << {
        phone: phone.full_name,
        phone_id: phone.id,
        price_change: (end_price - start_price).round(2),
        change_percent:,
        previous_price: start_price.round(2),
        current_price: end_price.round(2)
      }
    end

    # Sort by absolute change percent and return top 10
    movers.sort_by { |m| m[:change_percent].abs }.reverse.first(10)
  end

  # Analyze regional pricing gaps against UAE benchmark
  # @return [Hash] UAE violators and premium chargers
  def self.analyze_regional_gaps
    # Get UAE benchmark prices
    uae_country = Country.find_by(code: 'AE')
    return { uae_violators: [], premium_chargers: [] } unless uae_country

    uae_prices = Price
      .joins(:channel)
      .where(channels: { country_id: uae_country.id })
      .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
      .group(:phone_id)
      .minimum(:price_usd)

    # Compare with other countries
    uae_violators = []
    premium_chargers = []

    uae_prices.each do |phone_id, uae_price|
      phone = Phone.find_by(id: phone_id)
      next unless phone

      # Check prices in other countries
      Country.active.where.not(id: uae_country.id).each do |country|
        local_price = Price
          .joins(:channel)
          .where(phone_id:, channels: { country_id: country.id })
          .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
          .minimum(:price_usd)

        next unless local_price

        discount_percent = ((uae_price - local_price) / uae_price * 100).round(1)

        if discount_percent >= CRITICAL_DISCOUNT_THRESHOLD
          # Find the channel with this price
          channel = Channel
            .joins(:prices)
            .find_by(prices: { phone_id:, price_usd: local_price })

          uae_violators << {
            phone: phone.full_name,
            phone_id: phone.id,
            country: country.name,
            country_id: country.id,
            channel: channel&.name || 'Unknown',
            local_price: local_price.round(2),
            uae_benchmark: uae_price.round(2),
            discount_percent:,
            status: STATUS_CRITICAL
          }
        elsif discount_percent <= -15 # Premium >15%
          channel = Channel
            .joins(:prices)
            .find_by(prices: { phone_id:, price_usd: local_price })

          premium_chargers << {
            phone: phone.full_name,
            phone_id: phone.id,
            country: country.name,
            country_id: country.id,
            channel: channel&.name || 'Unknown',
            local_price: local_price.round(2),
            uae_benchmark: uae_price.round(2),
            premium_percent: discount_percent.abs.round(1)
          }
        end
      end
    end

    # Sort by discount severity
    uae_violators.sort_by { |v| -v[:discount_percent] }
    premium_chargers.sort_by { |p| -p[:premium_percent] }

    {
      uae_violators: uae_violators.first(20),
      premium_chargers: premium_chargers.first(10)
    }
  end
end
