# frozen_string_literal: true

namespace :import do
  desc "Import all data from CSV files"
  task all: %i[countries channels phones prices telco_plans exchange_rates promotions dubai_benchmarks]

  desc "Import countries from CSV"
  task countries: :environment do
    require "csv"

    file_path = "/tmp/meppi_export/countries.csv"
    count = 0

    CSV.foreach(file_path, headers: true) do |row|
      Country.create!(
        code: row["code"],
        name: row["name"],
        currency: row["currency"],
        exchange_source: row["exchange_source"],
        priority: row["priority"],
        active: row["active"] == "1",
        created_at: row["created_at"]
      )
      count += 1
    end

    puts "✅ Imported #{count} countries"
  end

  desc "Import channels from CSV"
  task channels: :environment do
    require "csv"

    file_path = "/tmp/meppi_export/channels.csv"
    count = 0

    CSV.foreach(file_path, headers: true) do |row|
      Channel.create!(
        country_id: row["country_id"],
        name: row["name"],
        channel_type: row["type"],
        url: row["url"],
        active: row["active"] == "1",
        created_at: row["created_at"]
      )
      count += 1
    end

    puts "✅ Imported #{count} channels"
  end

  desc "Import phones from CSV"
  task phones: :environment do
    require "csv"

    file_path = "/tmp/meppi_export/phones.csv"
    count = 0

    CSV.foreach(file_path, headers: true) do |row|
      Phone.create!(
        id: row["id"],  # Preserve original ID
        brand: row["brand"],
        model: row["model"],
        url: row["url"],
        image_url: row["image_url"],
        announced: row["announced"],
        released: row["released"],
        display_size: row["display_size"],
        display_type: row["display_type"],
        display_resolution: row["display_resolution"],
        chipset: row["chipset"],
        cpu: row["cpu"],
        gpu: row["gpu"],
        ram: row["ram"],
        storage: row["storage"],
        main_camera: row["main_camera"],
        selfie_camera: row["selfie_camera"],
        battery: row["battery"],
        os: row["os"],
        weight: row["weight"],
        dimensions: row["dimensions"],
        price: row["price"],
        specs_json: row["specs_json"],
        scraped_at: row["scraped_at"]
      )
      count += 1
    end

    puts "✅ Imported #{count} phones"
  end

  desc "Import prices from meppi.db"
  task prices: :environment do
    require "sqlite3"

    db = SQLite3::Database.new("/home/theanonymgee/dev/projects/meppi/meppi.db")
    count = 0

    db.execute("SELECT * FROM prices") do |row|
      phone_id = row[1]  # phone_id is at index 1

      # Skip if phone doesn't exist
      unless Phone.exists?(phone_id)
        puts "⚠️  Skipping price for missing phone_id: #{phone_id}"
        next
      end

      Price.create!(
        phone_id:,
        channel_id: row[2],     # channel_id
        price_local: row[3],    # price_local
        price_usd: row[4],      # price_usd
        price_type: row[5],     # price_type
        stock_status: row[6],   # stock_status
        url: row[7],            # url
        date: row[8],           # date
        scraped_at: row[9]      # scraped_at
      )
      count += 1
    end

    db.close
    puts "✅ Imported #{count} prices"
  end

  desc "Import telco_plans from meppi.db"
  task telco_plans: :environment do
    # Direct import from SQLite
    require "sqlite3"

    db = SQLite3::Database.new("/home/theanonymgee/dev/projects/meppi/meppi.db")
    count = 0

    db.execute("SELECT * FROM telco_plans") do |row|
      TelcoPlan.create!(
        channel_id: row[1],
        plan_name: row[2],
        monthly_fee_local: row[3],
        contract_months: row[4],
        data_gb: row[5],
        minutes: row[6],
        active: row[7] == 1,
        created_at: row[8]
      )
      count += 1
    end

    db.close
    puts "✅ Imported #{count} telco_plans"
  end

  desc "Import exchange_rates from meppi.db"
  task exchange_rates: :environment do
    require "sqlite3"

    db = SQLite3::Database.new("/home/theanonymgee/dev/projects/meppi/meppi.db")
    count = 0

    db.execute("SELECT * FROM exchange_rates") do |row|
      ExchangeRate.create!(
        country_id: row[1],
        rate_official: row[2],
        rate_black_market: row[3],
        rate_used: row[4],
        date: row[5],
        source: row[6]
      )
      count += 1
    end

    db.close
    puts "✅ Imported #{count} exchange_rates"
  end

  desc "Import promotions from meppi.db"
  task promotions: :environment do
    require "sqlite3"

    db = SQLite3::Database.new("/home/theanonymgee/dev/projects/meppi/meppi.db")
    count = 0

    db.execute("SELECT * FROM promotions") do |row|
      Promotion.create!(
        channel_id: row[1],
        phone_id: row[2],
        description: row[3],
        discount_percent: row[4],
        discount_amount_local: row[5],
        promo_code: row[6],
        valid_from: row[7],
        valid_until: row[8],
        created_at: row[9]
      )
      count += 1
    end

    db.close
    puts "✅ Imported #{count} promotions"
  end

  desc "Import dubai_benchmarks from meppi.db"
  task dubai_benchmarks: :environment do
    require "sqlite3"

    db = SQLite3::Database.new("/home/theanonymgee/dev/projects/meppi/meppi.db")
    count = 0

    db.execute("SELECT * FROM dubai_benchmark") do |row|
      DubaiBenchmark.create!(
        phone_id: row[1],
        price_aed: row[2],
        price_wholesale: row[3],
        date: row[4],
        scraped_at: row[5]
      )
      count += 1
    end

    db.close
    puts "✅ Imported #{count} dubai_benchmarks"
  end
end
