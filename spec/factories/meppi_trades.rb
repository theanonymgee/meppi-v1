# frozen_string_literal: true

FactoryBot.define do
  factory :meppi_trade do
    association :phone
    association :channel
    association :country

    sequence(:title) { |n| "Trade #{n}" }
    brand { 'Samsung' }
    price_local { 1000.0 }
    price_usd { 270.0 }
    currency { 'AED' }
    stock_status { 'in_stock' }
    url { 'https://example.com/trade' }
    trade_type { 'retail' }
    valid_until { 30.days.from_now }
    discount_percent { 10.0 }
    discount_amount_local { 100.0 }
    promo_code { 'SAVE10' }
  end
end
