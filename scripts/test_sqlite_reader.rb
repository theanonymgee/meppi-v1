#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for SQLite Reader
# Usage: RAILS_ENV=development ruby scripts/test_sqlite_reader.rb

require_relative '../config/environment'
require_relative '../lib/tasks/sqlite_reader'

puts "=" * 60
puts "SQLite Reader Test"
puts "=" * 60

# Create reader instance
reader = SqliteReader.new

puts "Database path: #{reader.instance_variable_get(:@db_path)}"
puts "Export directory: #{reader.instance_variable_get(:@export_dir)}"
puts

# Validate database
puts "1. Validating database..."
if reader.validate_database
  puts "   ✓ Database file found"
else
  puts "   ✗ Database file not found"
  exit 1
end

# Ensure export directory
puts "2. Creating export directory..."
reader.ensure_export_dir
puts "   ✓ Export directory ready"

# Run export
puts "3. Exporting data..."
result = reader.run_safe

puts
puts "=" * 60
puts "Export Results:"
puts "=" * 60

if result[:success]
  puts "✓ Export successful!"
  puts "  Tables exported: #{result[:tables_exported]}/#{result[:total_tables]}"
  puts "  Total records: #{result[:total_records]}"
  puts "  Export directory: #{result[:export_directory]}"

  # List exported files
  puts
  puts "Export files created:"
  Dir.glob(File.join(reader.instance_variable_get(:@export_dir), '*.csv')).each do |file|
    size = File.size(file)
    puts "  - #{File.basename(file)} (#{size} bytes)"
  end
else
  puts "✗ Export failed!"
  puts "  Error: #{result[:error]}"
  puts "  Message: #{result[:message]}"
  exit 1
end

puts
puts "=" * 60
