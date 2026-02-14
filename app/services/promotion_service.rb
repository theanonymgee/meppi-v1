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
    # Use MeppiTrade for promotions data
    trades_query = MeppiTrade.where.not(price_usd: [nil, 0])
                             .where.not(discount_percent: [nil, 0])

    trades_query = trades_query.where(country_id: country_id) if country_id

    # Build promotion data
    active_promos = build_promotion_data_from_trades(trades_query)

    # Calculate discount rankings
    discount_ranking = calculate_discount_rankings_from_trades(trades_query)

    {
      active_promotions: active_promos,
      discount_ranking:,
      total_count: active_promos.length,
      avg_discount: calculate_avg_discount(active_promos)
    }
  rescue StandardError => e
    Rails.logger.error("PromotionService error: #{e.message}")
    {
      active_promotions: [],
      discount_ranking: [],
      total_count: 0,
      avg_discount: 0.0
    }
  end

  # Get discounts by phone
  # @param phone_id [Integer] Phone ID
  # @return [Array<Hash>] Available discounts
  def self.discounts_for_phone(phone_id)
    phone = Phone.find_by(id: phone_id)
    return [] unless phone

    # Get all trades for this phone
    trades = MeppiTrade.where(phone_id:)
                       .where.not(price_usd: [nil, 0])
                       .includes(:channel)

    return [] if trades.empty?

    # Calculate average price
    avg_price = trades.average(:price_usd)&.round(2) || 0

    # Find promotional prices
    trades.map do |trade|
      discount_percent = trade.discount_percent || if avg_price.positive?
                                                     (((avg_price - trade.price_usd) / avg_price) * 100).round(1)
                                                   else
                                                     0
                                                   end

      {
        channel: trade.channel&.name || 'Unknown',
        channel_id: trade.channel_id,
        channel_type: trade.channel&.type || 'unknown',
        price: trade.price_usd.round(2),
        discount_percent: discount_percent.positive? ? discount_percent : 0,
        is_promotional: discount_percent >= 10
      }
    end.select { |p| p[:is_promotional] }.sort_by { |p| -p[:discount_percent] }
  rescue StandardError => e
    Rails.logger.error("PromotionService.discounts_for_phone error: #{e.message}")
    []
  end

  private

  # Build promotion data from MeppiTrade records
  def self.build_promotion_data_from_trades(trades_query)
    trades_query.map do |trade|
      phone = trade.phone
      channel = trade.channel
      next nil unless phone && channel

      # Use stored discount or calculate
      discount_percent = trade.discount_percent || 0

      {
        id: trade.id,
        phone: phone.full_name,
        phone_id: phone.id,
        channel: channel.name,
        channel_id: channel.id,
        original_price: trade.price_usd * (1 + discount_percent / 100.0),
        discounted_price: trade.price_usd.round(2),
        discount_percent: discount_percent,
        valid_until: trade.valid_until&.strftime('%Y-%m-%d'),
        days_remaining: calculate_days_remaining(trade.valid_until)
      }
    end.compact.select { |p| p[:discount_percent] >= 5 }
      .sort_by { |p| -p[:discount_percent] }
      .first(50)
  end

  # Calculate discount rankings from MeppiTrade records
  def self.calculate_discount_rankings_from_trades(trades_query)
    phone_discounts = trades_query.group_by(&:phone_id).transform_values do |trades|
      max_discount = trades.map { |t| t.discount_percent || 0 }.max || 0

      {
        phone: trades.first&.phone&.full_name || 'Unknown',
        phone_id: trades.first&.phone_id,
        max_discount: max_discount,
        channel_count: trades.map(&:channel_id).compact.uniq.count
      }
    end

    phone_discounts.values.sort_by { |d| -d[:max_discount] }.first(20)
  end

  # Calculate days remaining for promotion
  def self.calculate_days_remaining(valid_until)
    return nil unless valid_until
    days = (valid_until - Date.current).to_i
    days.positive? ? days : nil
  end

  # Calculate average discount
  def self.calculate_avg_discount(promotions)
    return 0.0 if promotions.empty?

    (promotions.sum { |p| p[:discount_percent] } / promotions.size.to_f).round(1)
  end
end
