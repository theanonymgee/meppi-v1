# frozen_string_literal: true

# Import prices from SQLite to PostgreSQL
# Run with: rails runner scripts/import_prices.rb

require "sqlite3"

puts "=== Price Data Import Script ==="

SQLITE_DB_PATH = "/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/meppi.db"

# Phone ID mapping for string phone_ids to numeric IDs
STRING_TO_NUMERIC_ID = {
  "Apple iPhone 15" => 1094,
  "Apple iPhone 15 Plus" => 1093,
  "Apple iPhone 15 Pro" => 1092,
  "Apple iPhone 15 Pro Max" => 1091,
  "Apple iPhone 16" => 1085,
  "Apple iPhone 16 Plus" => 1084,
  "Apple iPhone 16 Pro" => 1083,
  "Apple iPhone 16 Pro Max" => 1082,
  "Samsung Galaxy S24" => 69,
  "Samsung Galaxy S24 FE" => 44,
  "Samsung Galaxy S24 Ultra" => 67,
  "Samsung Galaxy S24+" => 68,
  "Samsung Galaxy S25" => 40,
  "Samsung Galaxy S25 Ultra" => 38,
  "Samsung Galaxy S25+" => 39
}

db = SQLite3::Database.new(SQLITE_DB_PATH, readonly: true)

# Get total count
total_count = db.get_first_value("SELECT COUNT(*) FROM prices")
puts "Total prices in SQLite: #{total_count}"

# Clear existing prices
puts "Clearing existing meppi_trades..."
MeppiTrade.delete_all

# Import prices
puts "Importing prices..."
imported = 0
skipped = 0
batch = []

db.execute("SELECT id, phone_id, channel_id, price_local, price_usd, price_type, stock_status, url, date FROM prices") do |row|
  _id, phone_id, channel_id, price_local, price_usd, price_type, stock_status, url, date = row

  # Convert string phone_id to numeric
  if phone_id.is_a?(String)
    numeric_id = STRING_TO_NUMERIC_ID[phone_id]
    if numeric_id.nil?
      skipped += 1
      next
    end
    phone_id = numeric_id
  end

  # Find the phone
  phone = Phone.find_by(id: phone_id)
  unless phone
    skipped += 1
    next
  end

  # Find the channel to get country_id
  channel = Channel.find_by(id: channel_id)
  country_id = channel&.country_id

  # Create meppi_trade record
  batch << {
    phone_id: phone_id,
    channel_id: channel_id,
    country_id: country_id,
    title: "#{phone.brand} #{phone.model}",
    brand: phone.brand,
    price_local: price_local,
    price_usd: price_usd,
    currency: "USD",
    stock_status: stock_status || "unknown",
    url: url,
    trade_type: price_type || "retail",
    discount_percent: 0,
    created_at: date,
    updated_at: Time.current
  }

  if batch.size >= 500
    MeppiTrade.insert_all(batch)
    imported += batch.size
    print "."
    batch = []
  end
end

# Insert remaining batch
if batch.any?
  MeppiTrade.insert_all(batch)
  imported += batch.size
end

puts ""
puts "Imported: #{imported}"
puts "Skipped: #{skipped}"
puts "Total meppi_trades: #{MeppiTrade.count}"

db.close
puts "Done!"
