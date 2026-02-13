# frozen_string_literal: true

# MEPPI Daily Update Task
# Runs all scrapers and exchange rate updates daily
# Orchestration: Multi-site data collection for pricing intelligence

namespace :meppi do
  desc "Daily update: Run all scrapers and update exchange rates"
  task daily_update: :environment do
    puts "=" * 60
    puts "🔄 MEPPI Daily Update Started"
    puts "=" * 60

    results = {
      exchange_rates: { updated: 0, errors: [] },
      scrapers: {
        amazon_ae: { collected: 0, errors: [] },
        noon_ae: { collected: 0, errors: [] },
        samsung_ae: { collected: 0, errors: [] },
        sharaf_dg: { collected: 0, errors: [] }
      }
    }

    # Phase 1: Update exchange rates
    puts "\n📊 Phase 1: Exchange Rates"
    puts "-" * 60

    begin
      exchange_result = ExchangeRateService.update_all_rates

      results[:exchange_rates][:updated] = exchange_result[:updated].count
      results[:exchange_rates][:skipped] = exchange_result[:skipped].count
      results[:exchange_rates][:errors] = exchange_result[:errors].count

      puts "  ✅ Updated: #{results[:exchange_rates][:updated]} rates"
      puts "  ⏭️  Skipped: #{results[:exchange_rates][:skipped]} rates"
      puts "  ❌ Errors: #{results[:exchange_rates][:errors]} rates"

    rescue StandardError => e
      results[:exchange_rates][:errors] << { message: e.message }
      puts "  ❌ Exchange rate update failed: #{e.message}"
    end

    # Phase 2: SerpAPI (Google Shopping) - replaces blocked Amazon scraper
    puts "\n🛒️ Phase 2: Google Shopping (via SerpAPI)"
    puts "-" * 60

    brands_to_scrape = ['samsung', 'apple', 'xiaomi', 'oppo', 'vivo', 'tecno', 'infinix', 'nokia']

    begin
      brands_to_scrape.each do |brand|
        begin
          listings = SerpApiScraperService.fetch_phones(brand: brand, country: 'ae')
          
          if listings.any?
            listings.each do |product|
              upsert_price(product, 'AE', product[:source] || 'Google Shopping')
              results[:scrapers][:amazon_ae][:collected] += 1
            end
            puts "    ✅ #{brand}: #{listings.count} products"
          else
            puts "    ⚠️ #{brand}: 0 products"
          end

        rescue StandardError => e
          results[:scrapers][:amazon_ae][:errors] << { brand: brand, error: e.message }
          puts "    ❌ Error scraping #{brand}: #{e.message}"
        end
      end

      puts "  ✅ Google Shopping: #{results[:scrapers][:amazon_ae][:collected]} products"

    rescue StandardError => e
      puts "  ❌ SerpAPI scraping failed: #{e.message}"
    end

    # Phase 3: Scrape Noon (multi-country)
    puts "\n🛒️ Phase 3: Noon"
    puts "-" * 60

    noon_countries = ['AE', 'SA', 'EG']

    begin
      noon_countries.each do |country_code|
        begin
          page = 1
          loop do
            listings = NoonScraperService.fetch_listings(brand: 'samsung', country_code:, page:)
            break if listings.empty?

            listings.each do |product|
              upsert_price(product, country_code, 'Noon')
              results[:scrapers]["noon_#{country_code.downcase}".to_sym][:collected] += 1
            end

            page += 1
            break if page > 3 # Max 3 pages per country
          end

        rescue StandardError => e
          results[:scrapers]["noon_#{country_code.downcase}".to_sym][:errors] << { country: country_code, error: e.message }
          puts "    ❌ Error scraping Noon #{country_code}: #{e.message}"
        end
      end

      puts "  ✅ Noon: #{noon_countries.sum { |c| results[:scrapers]["noon_#{c.downcase}".to_sym][:collected] }} products"

    rescue StandardError => e
      puts "  ❌ Noon scraping failed: #{e.message}"
    end

    # Phase 4: Scrape Samsung Official
    puts "\n📱 Phase 4: Samsung Official"
    puts "-" * 60

    samsung_countries = ['AE', 'SA', 'EG', 'JO', 'KW', 'QA', 'BH', 'OM']

    begin
      samsung_countries.each do |country_code|
        begin
          page = 1
          loop do
            listings = SamsungOfficialScraperService.fetch_listings(model: 'galaxy-s24', country_code:, page:)
            break if listings.empty?

            listings.each do |product|
              upsert_price(product, country_code, 'Samsung Official')
              results[:scrapers][:samsung_official][:collected] += 1
            end

            page += 1
            break if page > 3 # Max 3 pages per country
          end

        rescue StandardError => e
          results[:scrapers][:samsung_official][:errors] << { country: country_code, error: e.message }
          puts "    ❌ Error scraping Samsung #{country_code}: #{e.message}"
        end
      end

      puts "  ✅ Samsung: #{results[:scrapers][:samsung_official][:collected]} products"

    rescue StandardError => e
      puts "  ❌ Samsung scraping failed: #{e.message}"
    end

    # Phase 5: Scrape Sharaf DG
    puts "\n📱 Phase 5: Sharaf DG"
    puts "-" * 60

    sharaf_countries = ['AE', 'SA', 'QA']

    begin
      sharaf_countries.each do |country_code|
        begin
          page = 1
          loop do
            listings = SharafDgScraperService.fetch_listings(brand: 'samsung', country_code:, page:)
            break if listings.empty?

            listings.each do |product|
              upsert_price(product, country_code, 'Sharaf DG')
              results[:scrapers][:sharaf_dg][:collected] += 1
            end

            page += 1
            break if page > 3 # Max 3 pages per country
          end

        rescue StandardError => e
          results[:scrapers][:sharaf_dg][:errors] << { country: country_code, error: e.message }
          puts "    ❌ Error scraping Sharaf DG #{country_code}: #{e.message}"
        end
      end

      puts "  ✅ Sharaf DG: #{results[:scrapers][:sharaf_dg][:collected]} products"

    rescue StandardError => e
      puts "  ❌ Sharaf DG scraping failed: #{e.message}"
    end

    # Final Summary
    puts "\n" + "=" * 60
    puts "📊 DAILY UPDATE SUMMARY"
    puts "=" * 60

    total_collected = results[:scrapers].sum { |s| s[:collected] }
    total_errors = results[:scrapers].sum { |s| s[:errors].count } + results[:exchange_rates][:errors].count

    puts "Exchange Rates:"
    puts "  Updated: #{results[:exchange_rates][:updated]}"
    puts "  Skipped: #{results[:exchange_rates][:skipped]}"
    puts "  Errors: #{results[:exchange_rates][:errors].count}"
    puts ""
    puts "Scrapers:"
    results[:scrapers].each do |scraper, data|
      puts "  #{scraper}:"
      puts "    Collected: #{data[:collected]}"
      puts "    Errors: #{data[:errors].count}"
    end
    puts ""
    puts "Total Products Collected: #{total_collected}"
    puts "Total Errors: #{total_errors}"

    if total_errors.positive?
      puts "⚠️  Daily update completed with errors"
    else
      puts "✅ Daily update completed successfully"
    end
  end

  # Upsert price record (find or create by unique key)
  # @param product [Hash] Product data
  # @param country_code [String] Country code
  # @param source [String] Source name
  def upsert_price(product, country_code, source)
    country = Country.find_by(code: country_code)
    return unless country

    channel = Channel.find_or_create_by!(
      country: country,
      name: source,
      channel_type: 'retailer',
      url: product[:url],
      active: true
    )

    # Find or create phone record
    phone = Phone.find_or_create_by!(
      brand: product[:brand],
      model_name: product[:title] || product[:model]
    )

    # Create or update price record
    Price.create_or_find_by!(
      phone: phone,
      channel: channel,
      price_local: product[:price_local],
      price_usd: product[:price_usd],
      price_type: 'nominal',
      stock_status: product[:in_stock] ? 'in_stock' : 'out_of_stock',
      url: product[:url],
      date: Date.today
    )
  rescue StandardError => e
    puts "    ❌ Error upserting: #{e.message}"
  end
end
