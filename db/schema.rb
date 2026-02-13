# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_13_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "channels", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.string "name"
    t.string "channel_type"
    t.text "url"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_channels_on_country_id"
  end

# Could not dump table "chunks" because of following StandardError
#   Unknown type 'vector(1024)' for column 'embedding'

  create_table "countries", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "currency"
    t.string "exchange_source"
    t.integer "priority"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dubai_benchmarks", force: :cascade do |t|
    t.bigint "phone_id", null: false
    t.decimal "price_aed"
    t.decimal "price_wholesale"
    t.date "date"
    t.datetime "scraped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_id"], name: "index_dubai_benchmarks_on_phone_id"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.decimal "rate_official"
    t.decimal "rate_black_market"
    t.decimal "rate_used"
    t.date "date"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_exchange_rates_on_country_id"
  end

  create_table "meppi_trades", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

# Could not dump table "phones" because of following StandardError
#   Unknown type 'vector' for column 'embedding'

# Could not dump table "prices" because of following StandardError
#   Unknown type 'vector' for column 'embedding'

  create_table "promotions", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.bigint "phone_id", null: false
    t.text "description"
    t.decimal "discount_percent"
    t.decimal "discount_amount_local"
    t.string "promo_code"
    t.date "valid_from"
    t.date "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_promotions_on_channel_id"
    t.index ["phone_id"], name: "index_promotions_on_phone_id"
  end

  create_table "telco_device_prices", force: :cascade do |t|
    t.bigint "price_id", null: false
    t.bigint "telco_plan_id", null: false
    t.decimal "device_price_local"
    t.decimal "monthly_installment"
    t.decimal "total_cost_24m_local"
    t.decimal "effective_device_price"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_id"], name: "index_telco_device_prices_on_price_id"
    t.index ["telco_plan_id"], name: "index_telco_device_prices_on_telco_plan_id"
  end

  create_table "telco_plans", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.string "plan_name"
    t.decimal "monthly_fee_local"
    t.integer "contract_months"
    t.string "data_gb"
    t.string "minutes"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_telco_plans_on_channel_id"
  end

  add_foreign_key "channels", "countries"
  add_foreign_key "dubai_benchmarks", "phones"
  add_foreign_key "exchange_rates", "countries"
  add_foreign_key "meppi_trades", "channels"
  add_foreign_key "meppi_trades", "countries"
  add_foreign_key "meppi_trades", "phones"
  add_foreign_key "prices", "channels"
  add_foreign_key "promotions", "channels"
  add_foreign_key "promotions", "phones"
  add_foreign_key "telco_device_prices", "prices"
  add_foreign_key "telco_device_prices", "telco_plans"
  add_foreign_key "telco_plans", "channels"
end
