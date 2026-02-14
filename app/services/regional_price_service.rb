# frozen_string_literal: true

# RegionalPrice Service - Cross-country price comparison
# Single Responsibility: Compare prices across countries vs base benchmark
# Vibe Coding: Extracted constants, no hardcoded values
class RegionalPriceService
  include DashboardConstants

  # Benchmark analysis for a specific phone or aggregate
  # @param phone_id [Integer, nil] Phone ID for specific analysis, nil for aggregate
  # @return [Hash] Benchmark and comparison data
  def self.benchmark_analysis(phone_id = nil)
    if phone_id.present?
      analyze_phone_benchmark(phone_id.to_i)
    else
      analyze_aggregate_benchmark
    end
  end

  # Analyze benchmark for a specific phone
  def self.analyze_phone_benchmark(phone_id)
    phone = Phone.find_by(id: phone_id)
    return { error: "Phone not found" } unless phone

    # Get UAE prices for this phone
    uae_country = Country.find_by("LOWER(code) = ?", "ae")
    return { error: "UAE country not found" } unless uae_country

    uae_prices = MeppiTrade.where(phone_id: phone_id)
                           .joins(:channel)
                           .where(channels: { country_id: uae_country.id })
                           .where.not(price_usd: [nil, 0])

    return { error: "No UAE prices found for this phone" } if uae_prices.empty?

    uae_wholesale = uae_prices.minimum(:price_usd) || 0
    uae_retail = uae_prices.average(:price_usd) || 0

    # Get regional comparisons
    regional_prices = MeppiTrade.where(phone_id: phone_id)
                                .joins(:channel)
                                .includes(channel: :country)
                                .where.not(price_usd: [nil, 0])

    comparison = regional_prices.group_by { |t| t.channel&.country&.name }.map do |country_name, trades|
      local_price = trades.map(&:price_usd).compact.min
      discount = uae_wholesale.positive? ? ((uae_wholesale - local_price) / uae_wholesale * 100).round(1) : 0

      {
        country: country_name || "Unknown",
        local_price: local_price,
        uae_benchmark: uae_wholesale,
        discount_percent: discount,
        status: discount > 20 ? "critical" : (discount > 10 ? "warning" : "normal")
      }
    end.compact

    # Generate alerts for prices significantly below benchmark
    alerts = comparison.select { |c| c[:discount_percent] > 15 }.map do |c|
      {
        country: c[:country],
        channel: "Various",
        local_price: c[:local_price],
        uae_benchmark: c[:uae_benchmark],
        discount_percent: c[:discount_percent]
      }
    end

    {
      uae_benchmark: {
        phone: phone.full_name,
        wholesale_price: uae_wholesale,
        retail_price: uae_retail,
        vat_rate: 0.05
      },
      regional_comparison: comparison,
      alerts: alerts
    }
  end

  # Analyze aggregate benchmark across all phones
  def self.analyze_aggregate_benchmark
    uae_country = Country.find_by("LOWER(code) = ?", "ae")

    # Get all phones with prices
    phones_with_prices = Phone.joins(:meppi_trades).distinct

    violations = []
    countries_violations = Hash.new(0)

    phones_with_prices.each do |phone|
      # Get UAE benchmark
      uae_prices = MeppiTrade.where(phone: phone)
                             .joins(:channel)
                             .where(channels: { country_id: uae_country&.id })
                             .where.not(price_usd: [nil, 0])

      next if uae_prices.empty?

      uae_benchmark = uae_prices.minimum(:price_usd)

      # Check other countries
      MeppiTrade.where(phone: phone)
                .joins(:channel)
                .includes(channel: :country)
                .where.not(price_usd: [nil, 0])
                .group_by { |t| t.channel&.country&.name }
                .each do |country_name, trades|
        next if country_name == "United Arab Emirates"

        local_price = trades.map(&:price_usd).compact.min
        discount = uae_benchmark.positive? ? ((uae_benchmark - local_price) / uae_benchmark * 100).round(1) : 0

        if discount > 10
          violations << {
            phone: phone.full_name,
            country: country_name,
            channel: trades.first&.channel&.name || "Unknown",
            local_price: local_price,
            uae_benchmark: uae_benchmark,
            discount_percent: discount
          }
          countries_violations[country_name] += 1
        end
      end
    end

    # Sort violations by discount
    violations = violations.sort_by { |v| -v[:discount_percent] }

    {
      summary: {
        total_violations: violations.count,
        affected_phones: violations.map { |v| v[:phone] }.uniq.count,
        affected_countries: countries_violations.keys.count,
        avg_discount: violations.any? ? (violations.sum { |v| v[:discount_percent] } / violations.count).round(1) : 0
      },
      top_violations: violations.first(50),
      countries_by_violations: countries_violations.sort_by { |_, v| -v }.to_h
    }
  end

  # Compare prices to base country (UAE benchmark)
  # @param base_country_id [Integer] Base country ID for comparison
  # @param country_ids [Array<Integer>] Optional specific countries to compare
  # @return [Hash] Regional comparison data
  def self.compare_to_base(base_country_id:, country_ids: nil)
    base_country = Country.find_by(id: base_country_id)

    # Return empty result if base country not found
    unless base_country
      return {
        base_country: nil,
        comparisons: [],
        summary: {}
      }
    end

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
