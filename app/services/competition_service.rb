# frozen_string_literal: true

# Competition Service - Market analysis and competitive positioning
# Single Responsibility: Analyze market share and competitive landscape
# Vibe Coding: Extracted constants, no hardcoded values
class CompetitionService
  include DashboardConstants

  # Main entry point - Get comprehensive market analysis
  # @param country_id [Integer, nil] Optional country filter
  # @return [Hash] Market analysis data
  def self.market_analysis(country_id: nil)
    {
      market_share: calculate_brand_share(country_id),
      top_models: get_top_models(country_id),
      new_entries: get_new_entries(country_id)
    }
  end

  # Get market share by brand
  # @param country_id [Integer, nil] Optional country filter
  # @return [Hash] Brand market share percentages
  def self.market_share(country_id: nil)
    calculate_brand_share(country_id)
  end

  # Get top competing models
  # @param country_id [Integer, nil] Optional country filter
  # @param limit [Integer] Number of models to return
  # @return [Array<Hash>] Top models
  def self.top_models(country_id: nil, limit: 20)
    get_top_models(country_id, limit)
  end

  private

  # Calculate brand market share
  # @param country_id [Integer, nil] Country filter
  # @return [Hash] Brand percentages
  def self.calculate_brand_share(country_id)
    # Count phones by brand
    query = Phone.all

    # If country specified, count phones with prices in that country
    if country_id
      query = Phone.joins(:prices).where(prices: { date: DEFAULT_TIME_RANGE_DAYS.days.ago.. })
                    .joins(prices: { channel: :country })
                    .where(countries: { id: country_id })
                    .distinct
    end

    brand_counts = query.group(:brand).count
    total_phones = brand_counts.values.sum

    return {} if total_phones.zero?

    # Calculate percentages
    brand_counts.transform_values do |count|
      ((count.to_f / total_phones) * 100).round(1)
    end.sort_by { |_, share| -share }.to_h
  end

  # Get top models by price availability and competition
  # @param country_id [Integer, nil] Country filter
  # @param limit [Integer] Result limit
  # @return [Array<Hash>] Top models
  def self.get_top_models(country_id, limit = 20)
    # Get phones with most price points
    phones = Phone.select('phones.*, COUNT(prices.id) as price_count')
                  .joins(:prices)
                  .where('prices.date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                  .group('phones.id')
                  .order('price_count DESC')
                  .limit(limit)

    if country_id
      phones = phones.joins(prices: { channel: :country })
                    .where(countries: { id: country_id })
    end

    phones.map do |phone|
      avg_price = phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                             .average(:price_usd)&.round(2) || 0

      # Determine market position
      market_position = if avg_price >= MARKET_POSITION_PREMIUM_THRESHOLD
                          'premium'
                        elsif avg_price >= MARKET_POSITION_MIDRANGE_THRESHOLD
                          'mid-range'
                        else
                          'budget'
                        end

      # Count competitor phones (similar price range)
      competitors = Phone.joins(:prices)
                        .where('prices.date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                        .where.not(id: phone.id)
                        .where(prices: { price_usd: (avg_price * COMPETITOR_PRICE_RANGE_MIN)..(avg_price * COMPETITOR_PRICE_RANGE_MAX) })
                        .distinct
                        .count

      {
        phone: phone.full_name,
        phone_id: phone.id,
        brand: phone.brand,
        price_avg: avg_price,
        market_position:,
        competitor_count: competitors,
        price_points: phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date).count
      }
    end
  end

  # Get recently added phones
  # @param country_id [Integer, nil] Country filter
  # @return [Array<Hash>] New entries
  def self.get_new_entries(country_id)
    # Get phones created in the last 30 days
    recent_phones = Phone.where('created_at >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago)
                         .order(created_at: :desc)
                         .limit(NEW_ENTRIES_DISPLAY_LIMIT)

    recent_phones.map do |phone|
      # Count channels with prices
      channels = phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                            .joins(:channel)
                            .distinct
                            .count

      {
        phone: phone.full_name,
        phone_id: phone.id,
        brand: phone.brand,
        first_seen: phone.created_at.strftime('%Y-%m-%d'),
        channels:,
        has_prices: phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date).any?
      }
    end
  end

  # Compare multiple phones side by side
  # @param phone_ids [Array<Integer>] List of phone IDs to compare
  # @return [Hash] Comparison data with specs and pricing
  def self.compare_phones(phone_ids)
    raise ArgumentError, 'Phone IDs cannot be empty' if phone_ids.blank?
    raise ArgumentError, 'Please select 2-4 phones to compare' unless phone_ids.length.between?(COMPARISON_MIN_PHONES, COMPARISON_MAX_PHONES)

    phones = Phone.where(id: phone_ids).includes(:brand, :model, :screen_size, :battery, :camera, :storage, :prices)
    raise ArgumentError, 'Some phones not found' if phones.length != phone_ids.length

    phones.map do |phone|
      avg_price = phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                             .average(:price_usd)
                             .round(2) || 0

      market_position = if avg_price >= MARKET_POSITION_PREMIUM_THRESHOLD
                          'premium'
                        elsif avg_price >= MARKET_POSITION_MIDRANGE_THRESHOLD
                          'mid-range'
                        else
                          'budget'
                        end

      competitors = Phone.joins(:prices)
                        .where('prices.date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
                        .where.not(id: phone.id)
                        .where(prices: { price_usd: (avg_price * COMPETITOR_PRICE_RANGE_MIN)..(avg_price * COMPETITOR_PRICE_RANGE_MAX) })
                        .distinct
                        .count

      {
        phone: phone,
        phone_id: phone.id,
        brand: phone.brand,
        model: phone.model,
        screen_size: phone.screen_size,
        battery: phone.battery,
        camera: phone.camera,
        storage: phone.storage,
        avg_price: avg_price,
        market_position: market_position,
        competitor_count: competitors,
        price_points: phone.prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date).count
      }
    end
  end

  # Generate comparison insights
  # @param phone_data [Array<Hash>] Comparison data from compare_phones
  # @return [Hash] Insights including cheapest, most_expensive, coverage, diversity
  def self.generate_comparison_insights(phone_data)
    return {} if phone_data.blank?

    prices = phone_data.map { |d| d[:avg_price] }.compact
    return {} if prices.blank?

    {
      cheapest: phone_data.min_by { |d| d[:avg_price] || Float::INFINITY },
      most_expensive: phone_data.max_by { |d| d[:avg_price] || 0 },
      price_range: (prices.max - prices.min).round(2),
      avg_market_price: (prices.sum / prices.length).round(2),
      coverage_summary: "#{phone_data.map { |d| d[:market_position] }.uniq.join(', ')} market coverage",
      diversity_score: calculate_diversity_score(phone_data)
    }
  end

  private

  # Calculate diversity score based on specs and market positions
  # @param phone_data [Array<Hash>] Comparison data
  # @return [Float] Diversity score (0-1)
  def self.calculate_diversity_score(phone_data)
    return 0 if phone_data.blank?

    positions = phone_data.map { |d| d[:market_position] }.uniq
    brands = phone_data.map { |d| d[:brand] }.uniq

    # Higher score for more diverse options
    (positions.length * 0.4) + (brands.length * 0.1) + (phone_data.length * 0.05)
  end
end
