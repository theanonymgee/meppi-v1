# frozen_string_literal: true

# Import prices from SQLite to PostgreSQL using raw SQL
# Run with: rails runner scripts/import_prices_raw_sql.rb

require "sqlite3"

puts "=== Price Data Import Script (Raw SQL) ==="

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

# Clear existing prices using raw SQL
puts "Clearing existing meppi_trades..."
ActiveRecord::Base.connection.execute("DELETE FROM meppi_trades")

# Get max id to start from
max_id = ActiveRecord::Base.connection.select_value("SELECT COALESCE(MAX(id), 0) FROM meppi_trades")
puts "Starting ID: #{max_id + 1}"

# Import prices
puts "Importing prices..."
imported = 0
skipped = 0
current_id = max_id + 1
values = []

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
  country_id = channel&.country_id || 1

  # Escape single quotes
  title = "#{phone.brand} #{phone.model}".gsub("'", "''")
  brand = phone.brand.gsub("'", "''")
  url_escaped = url.to_s.gsub("'", "''")
  stock = stock_status.to_s.gsub("'", "''")
  trade_type = price_type.to_s.gsub("'", "''")
  date_val = date || "2026-02-13"

  values << "(#{current_id}, #{phone_id}, #{channel_id}, #{country_id}, '#{title}', '#{brand}', #{price_local || 0}, #{price_usd || 0}, 'USD', '#{stock}', '#{url_escaped}', '#{trade_type}', '#{date_val}', 0, NOW(), NOW())"
  current_id += 1
  imported += 1

  if values.size >= 500
    sql = "INSERT INTO meppi_trades (id, phone_id, channel_id, country_id, title, brand, price_local, price_usd, currency, stock_status, url, trade_type, valid_until, discount_percent, created_at, updated_at) VALUES #{values.join(', ')}"
    ActiveRecord::Base.connection.execute(sql)
    print "."
    values = []
  end
end

# Insert remaining batch
if values.any?
  sql = "INSERT INTO meppi_trades (id, phone_id, channel_id, country_id, title, brand, price_local, price_usd, currency, stock_status, url, trade_type, valid_until, discount_percent, created_at, updated_at) VALUES #{values.join(', ')}"
  ActiveRecord::Base.connection.execute(sql)
end

puts ""
puts "Imported: #{imported}"
puts "Skipped: #{skipped}"

# Update sequence
ActiveRecord::Base.connection.execute("SELECT setval('meppi_trades_id_seq', (SELECT MAX(id) FROM meppi_trades))")

puts "Total meppi_trades: #{MeppiTrade.count}"

db.close
puts "Done!"
