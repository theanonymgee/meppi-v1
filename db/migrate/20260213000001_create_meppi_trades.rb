# frozen_string_literal: true

class CreateMeppiTrades < ActiveRecord::Migration[7.1]
  def change
    create_table :meppi_trades do |t|
      t.bigint "phone_id"
      t.bigint "channel_id"
      t.bigint "country_id"
      t.string "title"
      t.string "brand"
      t.decimal "price_local"
      t.decimal "price_usd"
      t.string "currency"
      t.string "stock_status"
      t.text "url"
      t.string "trade_type"
      t.date "valid_until"
      t.decimal "discount_percent"
      t.decimal "discount_amount_local"
      t.string "promo_code"

      t.timestamps
    end

    add_foreign_key :meppi_trades, :channels
    add_foreign_key :meppi_trades, :countries
    add_foreign_key :meppi_trades, :phones
  end
end
