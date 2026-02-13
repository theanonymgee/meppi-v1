# frozen_string_literal: true

require_relative 'base_task'
require 'csv'
require 'date'

# PostgreSQL Importer Task
# Imports data from CSV exports into PostgreSQL database
class PostgresqlImporter < BaseTask
  IMPORT_DIR = ENV.fetch('MEPPI_EXPORT_DIR', 'tmp/exports')
  BATCH_SIZE = 100

  # Maps SQLite table names to import methods
  TABLES = %i[countries channels prices telco_plans telco_device_prices
                promotions exchange_rates dubai_benchmark].freeze

  def initialize(import_dir: nil)
    @import_dir = import_dir || IMPORT_DIR
    @stats = {}
  end

  def latest_csv_file(table_name)
    files = Dir.glob(File.join(@import_dir, "#{table_name}_export_*.csv"))
    files.sort_by { |f| File.mtime(f) }.last
  end

  def import_countries
    file = latest_csv_file('countries')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      Country.create_or_find_by!(
        code: row['code'],
        name: row['name'],
        currency: row['currency'],
        exchange_source: row['exchange_source'],
        priority: row['priority'] || 2,
        active: row['active'] == '1'
      )
      count += 1
    end

    { table: :countries, count: count }
  rescue StandardError => e
    { table: :countries, error: e.message }
  end

  def import_channels
    file = latest_csv_file('channels')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      country = Country.find_by(code: row['country_id'])
      next unless country

      Channel.create_or_find_by!(
        id: row['id'],
        country: country,
        name: row['name'],
        channel_type: row['type'],
        url: row['url'],
        active: row['active'] == '1'
      )
      count += 1
    end

    { table: :channels, count: count }
  rescue StandardError => e
    { table: :channels, error: e.message }
  end

  def import_telco_plans
    file = latest_csv_file('telco_plans')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      channel = Channel.find_by(id: row['channel_id'])
      next unless channel

      TelcoPlan.create_or_find_by!(
        id: row['id'],
        channel: channel,
        plan_name: row['plan_name'],
        monthly_fee_local: row['monthly_fee_local'],
        contract_months: row['contract_months'],
        data_gb: row['data_gb'],
        minutes: row['minutes'],
        active: row['active'] == '1'
      )
      count += 1
    end

    { table: :telco_plans, count: count }
  rescue StandardError => e
    { table: :telco_plans, error: e.message }
  end

  def import_promotions
    file = latest_csv_file('promotions')
    return { skipped: true, note: 'No promotions data' } unless file && File.size(file) > 0

    count = 0
    CSV.foreach(file, headers: true) do |row|
      channel = Channel.find_by(id: row['channel_id'])
      next unless channel

      Promotion.create_or_find_by!(
        id: row['id'],
        channel: channel,
        description: row['description'],
        discount_percent: row['discount_percent'],
        discount_amount_local: row['discount_amount_local'],
        promo_code: row['promo_code'],
        valid_from: parse_date(row['valid_from']),
        valid_until: parse_date(row['valid_until'])
      )
      count += 1
    end

    { table: :promotions, count: count }
  rescue StandardError => e
    { table: :promotions, error: e.message }
  end

  def import_exchange_rates
    file = latest_csv_file('exchange_rates')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      country = Country.find_by(code: row['currency'])
      next unless country

      ExchangeRate.create_or_find_by!(
        country: country,
        rate_official: row['usd_rate'],
        rate_black_market: row['usd_rate'],
        rate_used: row['usd_rate'],
        date: parse_date(row['updated_at']) || Date.today,
        source: 'imported'
      )
      count += 1
    end

    { table: :exchange_rates, count: count }
  rescue StandardError => e
    { table: :exchange_rates, error: e.message }
  end

  def import_dubai_benchmark
    file = latest_csv_file('dubai_benchmark')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      phone = Phone.find_by(id: row['phone_id'])
      next unless phone

      DubaiBenchmark.create_or_find_by!(
        phone: phone,
        price_aed: row['dubai_avg_usd'],
        price_wholesale: row['min_price_usd'],
        date: parse_date(row['updated_at']) || Date.today
      )
      count += 1
    end

    { table: :dubai_benchmark, count: count }
  rescue StandardError => e
    { table: :dubai_benchmark, error: e.message }
  end

  def import_prices
    file = latest_csv_file('prices')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      channel = Channel.find_by(id: row['channel_id'])
      next unless channel

      # Note: phone_id references external source, may not exist yet
      Price.create_or_find_by!(
        id: row['id'],
        channel: channel,
        price_local: row['price_local'],
        price_usd: row['price_usd'],
        date: parse_date(row['date']) || Date.today
      )
      count += 1
    end

    { table: :prices, count: count }
  rescue StandardError => e
    { table: :prices, error: e.message }
  end

  def import_telco_device_prices
    file = latest_csv_file('telco_device_prices')
    return { skipped: true } unless file

    count = 0
    CSV.foreach(file, headers: true) do |row|
      price = Price.find_by(id: row['price_id'])
      plan = TelcoPlan.find_by(id: row['plan_id'])
      next unless price && plan

      TelcoDevicePrice.create_or_find_by!(
        price: price,
        telco_plan: plan,
        device_price_local: row['device_price_local'],
        monthly_installment: row['monthly_installment'],
        total_cost_24m_local: row['total_cost_24m_local'],
        effective_device_price: row['effective_device_price'],
        notes: row['notes']
      )
      count += 1
    end

    { table: :telco_device_prices, count: count }
  rescue StandardError => e
    { table: :telco_device_prices, error: e.message }
  end

  def parse_date(date_string)
    return nil if date_string.nil? || date_string.empty?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end

  def execute
    results = []

    Rails.logger.info("Starting PostgreSQL import from #{@import_dir}")

    # Import in order: countries -> channels -> dependent tables
    import_order = [
      :import_countries,
      :import_channels,
      :import_telco_plans,
      :import_exchange_rates,
      :import_promotions,
      :import_dubai_benchmark,
      :import_prices,
      :import_telco_device_prices
    ]

    import_order.each do |method|
      result = send(method)
      results << result

      if result[:error]
        Rails.logger.error("Error importing #{result[:table]}: #{result[:error]}")
      elsif result[:skipped]
        Rails.logger.info("Skipped #{method}: #{result[:note] || 'No file found'}")
      else
        Rails.logger.info("Imported #{result[:count]} records to #{result[:table]}")
      end
    end

    successful_imports = results.count { |r| r[:count] }
    total_imported = results.sum { |r| r[:count] || 0 }

    {
      success: successful_imports.positive?,
      tables_processed: results.length,
      successful_imports: successful_imports,
      total_imported: total_imported,
      results: results
    }
  end
end
