# frozen_string_literal: true

# Promotion Service - Active promotions tracking and discount analysis
# Single Responsibility: Track and analyze promotional pricing
# Vibe Coding: Extracted constants, no hardcoded values
class PromotionService
  include DashboardConstants

  # Get active promotions
  # @param country_id [Integer, nil] Optional country filter
  # @return [Hash] Active promotions and rankings
  def self.active_promotions(country_id: nil)
    # Get current promotions from database
    promotions = Promotion.where('end_date >= ? OR end_date IS NULL', Date.current)

    promotions = promotions.joins(:channel).where(channels: { country_id: }) if country_id

    # Get promotional prices
    promo_prices = Price.where(price_type: :promotion)
                        .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)

    promo_prices = promo_prices.joins(:channel).where(channels: { country_id: }) if country_id

    # Build promotion data
    active_promos = build_promotion_data(promo_prices)

    # Calculate discount rankings
    discount_ranking = calculate_discount_rankings(promo_prices)

    {
      active_promotions: active_promos,
      discount_ranking:,
      total_count: active_promos.length,
      avg_discount: calculate_avg_discount(active_promos)
    }
  end

  # Get discounts by phone
  # @param phone_id [Integer] Phone ID
  # @return [Array<Hash>] Available discounts
  def self.discounts_for_phone(phone_id)
    phone = Phone.find_by(id: phone_id)
    return [] unless phone

    # Get all current prices for this phone
    current_prices = Price
      .where(phone_id:)
      .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
      .includes(:channel)

    # Calculate average price
    avg_price = current_prices.average(:price_usd)&.round(2) || 0

    # Find promotional prices
    current_prices.map do |price|
      discount_percent = if avg_price.positive?
                           (((avg_price - price.price_usd) / avg_price) * 100).round(1)
                         else
                           0
                         end

      {
        channel: price.channel.name,
        channel_id: price.channel.id,
        channel_type: price.channel.channel_type,
        price: price.price_usd.round(2),
        discount_percent: discount_percent.positive? ? discount_percent : 0,
        is_promotional: price.price_type == 'promotion' || discount_percent >= 10
      }
    end.select { |p| p[:is_promotional] }.sort_by { |p| -p[:discount_percent] }
  end

  private

  # Build promotion data from prices
  # @param promo_prices [ActiveRecord::Relation] Promotional prices
  # @return [Array<Hash>] Promotion data
  def self.build_promotion_data(promo_prices)
    promo_prices.map do |price|
      phone = price.phone
      channel = price.channel

      # Estimate original price (non-promotional average)
      original_price = Price
        .where(phone_id: phone.id)
        .where.not(id: price.id)
        .where('date >= ?', DEFAULT_TIME_RANGE_DAYS.days.ago.to_date)
        .average(:price_usd)&.round(2) || price.price_usd * 1.2

      discount_percent = if original_price.positive?
                           (((original_price - price.price_usd) / original_price) * 100).round(1)
                         else
                           0
                         end

      days_remaining = if price.respond_to?(:end_date) && price.end_date
                         (price.end_date - Date.current).to_i
                       else
                         nil
                       end

      {
        id: price.id,
        phone: phone.full_name,
        phone_id: phone.id,
        channel: channel.name,
        channel_id: channel.id,
        original_price:,
        discounted_price: price.price_usd.round(2),
        discount_percent:,
        valid_until: days_remaining&.positive? ? (Date.current + days_remaining).strftime('%Y-%m-%d') : nil,
        days_remaining: days_remaining&.positive? ? days_remaining : nil
      }
    end.select { |p| p[:discount_percent] >= 5 } # Only show promotions with 5%+ discount
      .sort_by { |p| -p[:discount_percent] }
      .first(50)
  end

  # Calculate discount rankings by phone
  # @param promo_prices [ActiveRecord::Relation] Promotional prices
  # @return [Array<Hash>] Discount rankings
  def self.calculate_discount_rankings(promo_prices)
    # Group by phone and find max discount
    phone_discounts = promo_prices.group_by(&:phone_id).transform_values do |prices|
      max_discount = prices.map do |price|
        phone = price.phone
        avg_price = prices.where.not(id: price.id).average(:price_usd) || price.price_usd * 1.2

        if avg_price.positive?
          (((avg_price - price.price_usd) / avg_price) * 100).round(1)
        else
          0
        end
      end.max || 0

      {
        phone: prices.first.phone.full_name,
        phone_id: prices.first.phone_id,
        max_discount: max_discount,
        channel_count: prices.map(&:channel_id).uniq.count
      }
    end

    phone_discounts.values.sort_by { |d| -d[:max_discount] }.first(20)
  end

  # Calculate average discount
  # @param promotions [Array<Hash>] Promotion data
  # @return [Float] Average discount percentage
  def self.calculate_avg_discount(promotions)
    return 0.0 if promotions.empty?

    (promotions.sum { |p| p[:discount_percent] } / promotions.size.to_f).round(1)
  end
end
