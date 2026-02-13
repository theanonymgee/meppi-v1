#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for PostgreSQL Importer
# Usage: RAILS_ENV=development ruby scripts/test_postgresql_importer.rb

require_relative '../config/environment'
require_relative '../lib/tasks/postgresql_importer'

puts "=" * 60
puts "PostgreSQL Importer Test"
puts "=" * 60

# Show current database state
puts "Current database state:"
puts "  Countries: #{Country.count}"
puts "  Channels: #{Channel.count}"
puts "  Prices: #{Price.count}"
puts "  Telco Plans: #{TelcoPlan.count}"
puts "  Telco Device Prices: #{TelcoDevicePrice.count}"
puts "  Promotions: #{Promotion.count}"
puts "  Exchange Rates: #{ExchangeRate.count}"
puts "  Dubai Benchmarks: #{DubaiBenchmark.count}"
puts

# Create importer instance
importer = PostgresqlImporter.new

# Run the import
puts "Starting import..."
puts "-" * 60

result = importer.run_safe

puts
puts "=" * 60
puts "Import Results:"
puts "=" * 60

if result[:success]
  puts "✓ Import successful!"
  puts "  Tables processed: #{result[:tables_processed]}"
  puts "  Successful imports: #{result[:successful_imports]}"
  puts "  Total records imported: #{result[:total_imported]}"
else
  puts "✗ Import completed with errors"
end

puts
puts "Detailed results:"
result[:results]&.each do |r|
  if r[:error]
    puts "  ✗ #{r[:table]}: #{r[:error]}"
  elsif r[:skipped]
    puts "  ⊝ #{r[:table] || 'unknown'}: #{r[:note] || 'Skipped'}"
  elsif r[:count]
    puts "  ✓ #{r[:table]}: #{r[:count]} records"
  end
end

puts
puts "New database state:"
puts "  Countries: #{Country.count}"
puts "  Channels: #{Channel.count}"
puts "  Prices: #{Price.count}"
puts "  Telco Plans: #{TelcoPlan.count}"
puts "  Telco Device Prices: #{TelcoDevicePrice.count}"
puts "  Promotions: #{Promotion.count}"
puts "  Exchange Rates: #{ExchangeRate.count}"
puts "  Dubai Benchmarks: #{DubaiBenchmark.count}"

puts
puts "=" * 60
