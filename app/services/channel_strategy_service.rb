# frozen_string_literal: true

# Channel Strategy Service - Channel price comparison and recommendations
# Single Responsibility: Analyze channel-specific pricing strategies
# Vibe Coding: No hardcoded values, single source of truth
class ChannelStrategyService
  include DashboardConstants

  # Analyze channel pricing for a specific phone
  # @param phone_id [Integer] Phone ID to analyze
  # @param country_id [Integer, nil] Optional country filter
  # @return [Hash] Channel analysis with recommendations
  def self.analyze(phone_id, country_id: nil)
    phone = Phone.find_by(id: phone_id)
    return { error: 'Phone not found' } unless phone

    # Fetch prices with associations (eager loading to prevent N+1)
    prices_query = Price
      .where(phone_id:)
      .includes(:channel)
      .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)

    prices_query = prices_query.joins(:channel).where(channels: { country_id: }) if country_id

    prices = prices_query.to_a

    return { error: 'No prices found for this phone' } if prices.empty?

    price_range = calculate_price_range(prices)
    channel_data = build_channel_data(prices, price_range)
    recommendations = generate_recommendations(channel_data, price_range)

    {
      phone: serialize_phone(phone),
      price_range:,
      channels: channel_data,
      recommendations:,
      country_filter: country_id
    }
  end

  # Get cheapest channels for a country
  # @param country_id [Integer] Country ID
  # @param limit [Integer] Number of results
  # @return [Array<Hash>] Cheapest channels
  def self.cheapest_channels(country_id:, limit: 10)
    # Find lowest prices by channel
    prices = Price
      .joins(:channel, :phone)
      .where(channels: { country_id: })
      .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
      .group('channels.id, phones.id')
      .select('channels.id, channels.name, phones.full_name, MIN(prices.price_usd) as min_price')
      .order('min_price ASC')
      .limit(limit)

    prices.map do |p|
      {
        channel_id: p.id,
        channel_name: p.name,
        phone_name: p.full_name,
        min_price: p.min_price.to_f.round(2)
      }
    end.to_a
  end

  # Get price range for a phone
  # @param phone_id [Integer] Phone ID
  # @param country_id [Integer, nil] Optional country filter
  # @return [Hash] Price range statistics
  def self.price_range(phone_id, country_id: nil)
    prices = Price.where(phone_id:)

    prices = prices.joins(:channel).where(channels: { country_id: }) if country_id

    prices = prices.where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)

    calculate_price_range(prices)
  end

  private

  # Calculate price range statistics
  # @param prices [ActiveRecord::Relation] Prices query
  # @return [Hash] Price range with spread
  def self.calculate_price_range(prices)
    min_price = prices.minimum(:price_usd)&.round(2) || 0
    max_price = prices.maximum(:price_usd)&.round(2) || 0
    avg_price = prices.average(:price_usd)&.round(2) || 0

    spread_percent = if min_price.positive?
                       (((max_price - min_price) / min_price) * 100).round(1)
                     else
                       0
                     end

    {
      min: min_price,
      max: max_price,
      avg: avg_price,
      spread_percent:
    }
  end

  # Build channel data array
  # @param prices [Array<Price>] Price records
  # @param price_range [Hash] Price range statistics
  # @return [Array<Hash>] Channel data
  def self.build_channel_data(prices, price_range)
    avg_price = price_range[:avg]
    min_price = price_range[:min]

    prices.map do |price|
      channel = price.channel
      discount_from_avg = if avg_price.positive?
                            (((avg_price - price.price_usd) / avg_price) * 100).round(1)
                          else
                            0
                          end

      {
        id: channel.id,
        name: channel.name,
        channel_type: channel.channel_type,
        price_usd: price.price_usd.round(2),
        is_cheapest: price.price_usd == min_price,
        discount_from_avg:,
        recommendation: determine_recommendation(discount_from_avg, price.price_usd, min_price)
      }
    end.sort_by { |c| c[:price_usd] }
  end

  # Determine channel recommendation
  # @param discount_from_avg [Float] Discount percentage
  # @param price [Float] Current price
  # @param min_price [Float] Minimum price
  # @return [String] Recommendation level
  def self.determine_recommendation(discount_from_avg, price, min_price)
    return 'best_value' if price == min_price && discount_from_avg >= BEST_VALUE_THRESHOLD
    return 'great_deal' if discount_from_avg >= BEST_VALUE_THRESHOLD
    return 'good_price' if discount_from_avg >= 10
    return 'fair_price' if discount_from_avg >= -5
    'overpriced'
  end

  # Generate actionable recommendations
  # @param channels [Array<Hash>] Channel data
  # @param price_range [Hash] Price range
  # @return [Array<Hash>] Recommendations
  def self.generate_recommendations(channels, price_range)
    recommendations = []
    avg_price = price_range[:avg]
    min_price = price_range[:min]

    # Best value channels
    best_value = channels.select { |c| c[:discount_from_avg] >= BEST_VALUE_THRESHOLD }
    best_value.each do |channel|
      recommendations << {
        channel_id: channel[:id],
        channel_name: channel[:name],
        reason: "Price is #{channel[:discount_from_avg]}% below market average",
        priority: channel[:price_usd] <= (avg_price * 0.8) ? :high : :medium,
        type: 'best_value'
      }
    end

    # Cheapest overall
    cheapest = channels.find { |c| c[:is_cheapest] }
    if cheapest
      recommendations << {
        channel_id: cheapest[:id],
        channel_name: cheapest[:name],
        reason: "Lowest price available ($#{cheapest[:price_usd]})",
        priority: :high,
        type: 'lowest_price'
      }
    end

    # Avoid overpriced channels
    overpriced = channels.select { |c| c[:discount_from_avg] < -10 }
    overpriced.each do |channel|
      recommendations << {
        channel_id: channel[:id],
        channel_name: channel[:name],
        reason: "Price is #{channel[:discount_from_avg].abs}% above market average",
        priority: :low,
        type: 'avoid'
      }
    end

    # Sort by priority
    recommendations.sort_by { |r| { high: 0, medium: 1, low: 2 }[r[:priority]] || 3 }
  end

  # Serialize phone for response
  # @param phone [Phone] Phone record
  # @return [Hash] Phone data
  def self.serialize_phone(phone)
    {
      id: phone.id,
      full_name: phone.full_name,
      brand: phone.brand,
      model: phone.model,
      url: phone.url,
      display_type: phone.display_type,
      storage: phone.storage,
      ram: phone.ram,
      main_camera: phone.main_camera
    }
  end
end
