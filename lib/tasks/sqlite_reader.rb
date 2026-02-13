# frozen_string_literal: true

require_relative 'base_task'
require 'sqlite3'
require 'csv'

# SQLite Reader Task
class SqliteReader < BaseTask
  DB_PATH = ENV.fetch('MEPPI_SQLITE_PATH', 'meppi.db')
  EXPORT_DIR = ENV.fetch('MEPPI_EXPORT_DIR', 'tmp/exports')

  TABLES = {
    countries: 'SELECT * FROM countries',
    channels: 'SELECT * FROM channels',
    prices: 'SELECT * FROM prices',
    telco_plans: 'SELECT * FROM telco_plans',
    telco_device_prices: 'SELECT * FROM telco_device_prices',
    promotions: 'SELECT * FROM promotions',
    exchange_rates: 'SELECT * FROM exchange_rates',
    dubai_benchmark: 'SELECT * FROM dubai_benchmark',
    effective_prices: 'SELECT * FROM effective_prices',
    cheapest_prices_per_phone: 'SELECT * FROM cheapest_prices_per_phone',
    most_expensive_prices_per_phone: 'SELECT * FROM most_expensive_prices_per_phone',
    country_price_comparison: 'SELECT * FROM country_price_comparison'
  }

  def initialize(db_path: nil, export_dir: nil)
    @db_path = db_path || DB_PATH
    @export_dir = export_dir || EXPORT_DIR
  end

  def validate_database
    File.exist?(@db_path)
  end

  def ensure_export_dir
    FileUtils.mkdir_p(@export_dir) unless Dir.exist?(@export_dir)
  end

  def export_table(table_name, connection)
    Rails.logger.info("Exporting table: #{table_name}")

    begin
      query = TABLES[table_name]

      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      filename = File.join(@export_dir, "#{table_name}_export_#{timestamp}.csv")

      # Get total count
      count_query = "SELECT COUNT(*) FROM (#{query})"
      total_count = connection.execute(count_query).first[0]

      CSV.open(filename, 'w') do |csv|
        # Execute query and get column names from first row
        rows = connection.execute(query)

        if rows.any?
          # Get column names from the first row (it's a hash with keys as column names)
          columns = rows.first.keys
          csv << columns

          # Write all rows as arrays
          rows.each do |row|
            csv << columns.map { |col| row[col] }
          end
        end

        {
          success: true,
          table: table_name,
          filename: filename,
          record_count: total_count,
          rows_written: rows.length
        }
      end
    rescue SQLite3::SQLException => e
      raise "SQLite query failed: #{e.message}"
    rescue StandardError => e
      raise "Export failed: #{e.message}"
    end
  end

  def execute_export_all(connection)
    Rails.logger.info("Starting SQLite data export...")

    unless validate_database
      return {
        success: false,
        error: 'Database file not found',
        path: @db_path
      }
    end

    ensure_export_dir

    results = TABLES.keys.map do |table_name|
      export_table(table_name, connection)
    end

    total_records = results.sum { |r| r[:record_count] || 0 }
    files_created = results.count { |r| r[:success] ? 1 : 0 }

    {
      success: true,
      tables_exported: files_created,
      total_tables: TABLES.keys.length,
      total_records: total_records,
      export_directory: @export_dir
    }
  end

  def execute
    begin
      before_execute

      connection = SQLite3::Database.new(@db_path)
      connection.results_as_hash = true

      result = execute_export_all(connection)

      connection.close

      after_execute(result)
      result
    rescue SQLite3::SQLException => e
      Rails.logger.error("SQLite connection error: #{e.message}")
      on_error(e)
      raise "Failed to connect to database: #{e.message}"
    rescue StandardError => e
      Rails.logger.error("Export failed: #{e.message}")
      on_error(e)
      raise "Export process failed: #{e.message}"
    ensure
      connection&.close
    end
  end
end
