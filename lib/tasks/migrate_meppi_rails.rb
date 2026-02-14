#!/usr/bin/env ruby
# lib/tasks/migrate_meppi_rails.rb
# MEPPI-Rails specific migration script

require_relative 'sqlite_to_postgresql'

class MigrateMeppiRails < SqliteToPostgresql
  MIGRATION_ORDER = %w[
    countries
    channels
    prices
    telco_plans
    telco_device_prices
    promotions
    effective_prices
    exchange_rates
    dubai_benchmark
  ]

  def initialize
    super(
      File.join(File.dirname(__FILE__), '..', '..', 'meppi.db'),
      ENV['DATABASE_URL'] || 'postgresql://meppi_rails:dev_password_123@localhost:5432/meppi_rails_development'
    )
  end

  def run
    puts "\n" + "=" * 60
    puts "MEPPI-Rails Database Migration"
    puts "=" * 60

    MIGRATION_ORDER.each_with_index do |table_name, index|
      puts "\n[#{index + 1}/#{MIGRATION_ORDER.size}] Processing: #{table_name}"
      puts "-" * 60

      begin
        create_table(table_name)
        migrate_data(table_name)
        verify(table_name)
      rescue => e
        puts "  ❌ Failed: #{e.message}"
        raise
      end
    end

    puts "\n" + "=" * 60
    puts "✓ MEPPI-Rails migration complete!"
    puts "=" * 60
  end
end

if __FILE__ == $0
  migrator = MigrateMeppiRails.new
  migrator.run
end
