# frozen_string_literal: true

require 'sqlite3'

# Connect to SQLite
sqlite_db = SQLite3::Database.new('meppi.db')

# Import Countries
puts 'Importing countries...'
sqlite_db.execute('SELECT id, code, name, currency, exchange_source, priority, active FROM countries').each do |row|
  id, code, name, currency, exchange_source, priority, active = row
  begin
    c = Country.find_or_initialize_by(id: id)
    c.code = code
    c.name = name
    c.currency = currency
    c.exchange_source = exchange_source || 'official'
    c.priority = priority || 1
    c.active = active == 1
    c.save!
    puts "  Created/Updated country: #{name}"
  rescue StandardError => e
    puts "  Skipped country #{name}: #{e.message}"
  end
end

puts "Total countries: #{Country.count}"

# Import Channels
puts "\nImporting channels..."
sqlite_db.execute('SELECT id, country_id, name, type, url, active FROM channels').each do |row|
  id, country_id, name, channel_type, url, active = row
  begin
    c = Channel.find_or_initialize_by(id: id)
    c.country_id = country_id
    c.name = name
    c.type = channel_type
    c.url = url
    c.active = active == 1
    c.save!
    puts "  Created/Updated channel: #{name}"
  rescue StandardError => e
    puts "  Skipped channel #{name}: #{e.message}"
  end
end

puts "Total channels: #{Channel.count}"

# Verify data linkage
puts "\nVerifying data linkage..."
puts "  Phones with trades: #{Phone.joins(:meppi_trades).distinct.count}"
puts "  Trades with valid channels: #{MeppiTrade.joins(:channel).count}"
puts "  Trades with valid countries: #{MeppiTrade.joins(:country).count}"
