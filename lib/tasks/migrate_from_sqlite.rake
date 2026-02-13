# frozen_string_literal: true

namespace :db do
  namespace :migrate do
    desc 'Migrate data from SQLite to PostgreSQL'
    task from_sqlite: :environment do
      # SQLite database path
      sqlite_db_path = ENV['SQLITE_DB_PATH'] || '../meppi/meppi.db'
      dry_run = ENV['DRY_RUN'] == 'true'

      puts "SQLite Database: #{sqlite_db_path}"
      puts "Dry Run: #{dry_run ? 'YES' : 'NO'}"
      puts '=' * 80

      # Check if SQLite database exists
      unless File.exist?(sqlite_db_path)
        abort "Error: SQLite database not found at #{sqlite_db_path}"
      end

      # Connect to SQLite
      require 'sqlite3'
      sqlite_db = SQLite3::Database.new(sqlite_db_path)
      sqlite_db.results_as_hash = true

      begin
        # Get counts from SQLite
        puts "\n📊 SQLite Data Counts:"
        sqlite_counts = {}
        %w[countries channels prices telco_plans telco_device_prices promotions exchange_rates dubai_benchmark].each do |table|
          result = sqlite_db.execute("SELECT COUNT(*) as count FROM #{table}")
          sqlite_counts[table] = result.first['count']
          puts "  #{table}: #{sqlite_counts[table]}"
        end

        # Get counts from PostgreSQL
        puts "\n📊 PostgreSQL Data Counts (before migration):"
        pg_counts = {}
        %w[countries channels prices telco_plans telco_device_prices promotions exchange_rates dubai_benchmarks].each do |table|
          pg_counts[table] = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
          puts "  #{table}: #{pg_counts[table]}"
        end

        if dry_run
          puts "\n✅ DRY-RUN MODE: No data will be migrated."
          puts '=' * 80
          exit
        end

        puts "\n🔄 Starting data migration..."
        puts '=' * 80

        # Migrate countries
        migrate_table(
          sqlite_db:,
          table_name: 'countries',
          pg_model: Country,
          column_mapping: {
            'id' => :id,
            'code' => :code,
            'name' => :name,
            'currency' => :currency,
            'exchange_source' => :exchange_source,
            'priority' => :priority,
            'active' => :active,
            'created_at' => :created_at
          },
          sqlite_count: sqlite_counts['countries']
        )

        # Migrate channels
        migrate_table(
          sqlite_db:,
          table_name: 'channels',
          pg_model: Channel,
          column_mapping: {
            'id' => :id,
            'country_id' => :country_id,
            'name' => :name,
            'type' => :channel_type,  # Map 'type' to 'channel_type'
            'url' => :url,
            'active' => :active,
            'created_at' => :created_at
          },
          sqlite_count: sqlite_counts['channels']
        )

        # Migrate prices
        migrate_table(
          sqlite_db:,
          table_name: 'prices',
          pg_model: Price,
          column_mapping: {
            'id' => :id,
            'phone_id' => :phone_id,
            'channel_id' => :channel_id,
            'price_local' => :price_local,
            'price_usd' => :price_usd,
            'price_type' => :price_type,
            'stock_status' => :stock_status,
            'url' => :url,
            'date' => :date,
            'scraped_at' => :created_at  # Map scraped_at to created_at
          },
          sqlite_count: sqlite_counts['prices']
        )

        # Migrate telco_plans
        migrate_table(
          sqlite_db:,
          table_name: 'telco_plans',
          pg_model: TelcoPlan,
          column_mapping: {
            'id' => :id,
            'channel_id' => :channel_id,
            'plan_name' => :plan_name,
            'monthly_fee_local' => :monthly_fee_local,
            'contract_months' => :contract_months,
            'data_gb' => :data_gb,
            'minutes' => :minutes,
            'active' => :active,
            'created_at' => :created_at
          },
          sqlite_count: sqlite_counts['telco_plans']
        )

        # Migrate telco_device_prices
        migrate_table(
          sqlite_db:,
          table_name: 'telco_device_prices',
          pg_model: TelcoDevicePrice,
          column_mapping: {
            'id' => :id,
            'price_id' => :price_id,
            'plan_id' => :telco_plan_id,  # Map plan_id to telco_plan_id
            'device_price_local' => :device_price_local,
            'monthly_installment' => :monthly_installment,
            'total_cost_24m_local' => :total_cost_24m_local,
            'effective_device_price' => :effective_device_price,
            'notes' => :notes
          },
          sqlite_count: sqlite_counts['telco_device_prices']
        )

        # Migrate promotions
        migrate_table(
          sqlite_db:,
          table_name: 'promotions',
          pg_model: Promotion,
          column_mapping: {
            'id' => :id,
            'channel_id' => :channel_id,
            'phone_id' => :phone_id,
            'description' => :description,
            'discount_percent' => :discount_percent,
            'discount_amount_local' => :discount_amount_local,
            'promo_code' => :promo_code,
            'valid_from' => :valid_from,
            'valid_until' => :valid_until,
            'created_at' => :created_at
          },
          sqlite_count: sqlite_counts['promotions']
        )

        # Migrate exchange_rates
        # Note: SQLite schema is different from Rails schema
        # SQLite: currency, usd_rate, updated_at
        # Rails: country_id, rate_official, rate_black_market, rate_used, date, source
        puts "\n📦 Migrating exchange_rates..."
        puts "   SQLite count: #{sqlite_counts['exchange_rates']}"

        pg_before_count = ExchangeRate.count

        rows = sqlite_db.execute('SELECT * FROM exchange_rates')
        migrated_count = 0

        rows.each do |row|
          currency = row['currency']
          usd_rate = row['usd_rate']
          updated_at = row['updated_at']

          # Find country by currency
          country = Country.find_by(currency:)
          if country.nil?
            puts "   ⚠️  Warning: No country found for currency #{currency}"
            next
          end

          # Create exchange rate
          begin
            ExchangeRate.create!(
              country_id: country.id,
              rate_official: usd_rate,
              rate_black_market: nil,
              rate_used: usd_rate,
              date: updated_at.to_date,
              source: 'sqlite_migration',
              created_at: updated_at,
              updated_at:
            )
            migrated_count += 1
          rescue ActiveRecord::RecordInvalid => e
            puts "   ⚠️  Error creating exchange rate: #{e.message}"
          end
        end

        pg_after_count = ExchangeRate.count
        puts "   Migrated: #{migrated_count}"
        puts "   PostgreSQL count: #{pg_before_count} → #{pg_after_count}"

        if pg_after_count == sqlite_counts['exchange_rates']
          puts "   ✅ Validation passed"
        else
          puts "   ⚠️  Validation warning: expected #{sqlite_counts['exchange_rates']}, got #{pg_after_count}"
        end

        # Migrate dubai_benchmark
        # Note: Schema is incompatible - SQLite has benchmark stats, Rails has price tracking
        # Skip migration for now as the data structure is completely different
        puts "\n📦 Skipping dubai_benchmark migration (incompatible schema)"
        puts "   SQLite count: #{sqlite_counts['dubai_benchmark']}"
        puts "   ℹ️  SQLite schema: phone_id, dubai_avg_usd, min_price_usd, max_price_usd, channel_count"
        puts "   ℹ️  Rails schema: id, phone_id, price_aed, price_wholesale, date, scraped_at"
        puts "   ⚠️  Schema mismatch - data cannot be migrated without transformation"
        puts "   ✅ Skipping"

        puts "\n" + '=' * 80
        puts '✅ Data migration completed successfully!'
        puts '=' * 80

        # Final validation
        puts "\n📊 Final Data Validation:"
        %w[countries channels prices telco_plans telco_device_prices promotions exchange_rates].each do |table|
          pg_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
          sqlite_count = sqlite_counts[table]
          status = pg_count == sqlite_count ? '✅' : '❌'
          puts "  #{status} #{table}: SQLite=#{sqlite_count}, PostgreSQL=#{pg_count}"
        end

        puts "  ⏭️  dubai_benchmark: Skipped (incompatible schema)"

      ensure
        sqlite_db.close
      end
    end

    desc 'Validate data migration from SQLite to PostgreSQL'
    task validate: :environment do
      sqlite_db_path = ENV['SQLITE_DB_PATH'] || '../meppi/meppi.db'

      unless File.exist?(sqlite_db_path)
        abort "Error: SQLite database not found at #{sqlite_db_path}"
      end

      require 'sqlite3'
      sqlite_db = SQLite3::Database.new(sqlite_db_path)
      sqlite_db.results_as_hash = true

      begin
        puts '📊 Data Validation Report'
        puts '=' * 80

        tables_to_check = [
          { sqlite: 'countries', pg: 'countries' },
          { sqlite: 'channels', pg: 'channels' },
          { sqlite: 'prices', pg: 'prices' },
          { sqlite: 'telco_plans', pg: 'telco_plans' },
          { sqlite: 'telco_device_prices', pg: 'telco_device_prices' },
          { sqlite: 'promotions', pg: 'promotions' },
          { sqlite: 'exchange_rates', pg: 'exchange_rates' }
          # Skip dubai_benchmark validation - schemas are incompatible
        ]

        all_match = true
        tables_to_check.each do |table_info|
          sqlite_count = sqlite_db.execute("SELECT COUNT(*) as count FROM #{table_info[:sqlite]}").first['count']
          pg_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table_info[:pg]}").first['count']
          match = sqlite_count == pg_count
          status = match ? '✅' : '❌'
          puts "#{status} #{table_info[:sqlite]}: SQLite=#{sqlite_count}, PostgreSQL=#{pg_count}"
          all_match &&= match
        end

        puts '=' * 80
        if all_match
          puts '✅ All data counts match!'
        else
          puts '❌ Some data counts do not match!'
        end
      ensure
        sqlite_db.close
      end
    end

    private

    def migrate_table(sqlite_db:, table_name:, pg_model:, column_mapping:, sqlite_count:, skip_id: false)
      puts "\n📦 Migrating #{table_name}..."
      puts "   SQLite count: #{sqlite_count}"

      # Get PostgreSQL count before migration
      pg_table_name = table_name == 'dubai_benchmark' ? 'dubai_benchmarks' : table_name
      pg_before_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{pg_table_name}").first['count']

      # Fetch data from SQLite
      rows = sqlite_db.execute("SELECT * FROM #{table_name}")
      migrated_count = 0
      skipped_count = 0

      rows.each do |row|
        # Map columns
        attributes = {}
        column_mapping.each do |sqlite_col, pg_attr|
          attributes[pg_attr] = row[sqlite_col]
        end

        # Skip if ID exists and we're not skipping ID
        unless skip_id
          existing = pg_model.find_by(id: attributes[:id])
          if existing
            skipped_count += 1
            next
          end
        end

        # Create or update record
        begin
          pg_model.create!(attributes)
          migrated_count += 1
        rescue ActiveRecord::RecordInvalid => e
          puts "   ⚠️  Error creating record: #{e.message}"
        end
      end

      # Get PostgreSQL count after migration
      pg_after_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{pg_table_name}").first['count']

      puts "   Migrated: #{migrated_count}"
      puts "   Skipped: #{skipped_count}" if skipped_count > 0
      puts "   PostgreSQL count: #{pg_before_count} → #{pg_after_count}"

      # Validate
      expected_count = skip_id ? sqlite_count : (pg_before_count + sqlite_count)
      if pg_after_count == expected_count || pg_after_count == sqlite_count
        puts "   ✅ Validation passed"
      else
        puts "   ⚠️  Validation warning: expected #{expected_count}, got #{pg_after_count}"
      end
    end
  end
end
