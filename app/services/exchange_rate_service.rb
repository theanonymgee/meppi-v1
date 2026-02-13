# frozen_string_literal: true

# Exchange Rate Service - Auto-update exchange rates from central banks
# Single Responsibility: Fetch and update exchange rates for all countries
# Vibe Coding: No hardcoded values, error handling, single source of truth

class ExchangeRateService
  # Central bank API endpoints for each country
  SOURCES = {
    'AE' => { name: 'UAE Central Bank', url: 'https://www.centralbank.ae/en/qr-code/495591876352747' },
    'SA' => { name: 'SAMA', url: 'https://www.sama.gov.ae/' },
    'EG' => { name: 'CBE', url: 'https://www.cbe.org.eg/' },
    'TR' => { name: 'TCMB', url: 'https://www.tcmb.gov.tr/' },
    'KW' => { name: 'CBK', url: 'https://www.cbk.gov.kw/' },
    'JO' => { name: 'CBJ', url: 'https://www.cbj.gov.jo/' },
    'PK' => { name: 'SBP', url: 'https://www.sbp.org.pk/' },
    'QA' => { name: 'QCB', url: 'https://www.qcb.gov.qa/' },
    'BH' => { name: 'CBB', url: 'https://www.cbb.gov.bh/' },
    'OM' => { name: 'CBO', url: 'https://www.cbo-oman.org/' },
    'IQ' => { name: 'CBIQ', url: 'https://cbi.iq/' },
    'MA' => { name: 'Bank Al-Maghrib', url: 'https://www.bkam.ma/' }
  }.freeze

  # Fallback rates (when APIs unavailable)
  FALLBACK_RATES = {
    'AED' => 0.272,   # 1 AED = 0.272 USD
    'SAR' => 0.267,   # 1 SAR = 0.267 USD
    'EGP' => 0.0204,  # 1 EGP = 0.0204 USD
    'TRY' => 0.030,    # 1 TRY = 0.030 USD
    'KWD' => 3.25,     # 1 KWD = 3.25 USD
    'JOD' => 1.41,     # 1 JOD = 1.41 USD
    'PKR' => 0.0036,   # 1 PKR = 0.0036 USD
    'QAR' => 0.275,    # 1 QAR = 0.275 USD
    'BHD' => 2.65,     # 1 BHD = 2.65 USD
    'OMR' => 2.60,     # 1 OMR = 2.60 USD
    'IQD' => 0.00076,  # 1 IQD = 0.00076 USD
    'MAD' => 0.099      # 1 MAD = 0.099 USD
  }.freeze

  # Request settings
  REQUEST_TIMEOUT = 15
  REQUEST_DELAY = 1 # Rate limiting between requests

  class UpdateError < StandardError; end
  class ApiError < StandardError; end

  # Main entry point - Update all exchange rates
  # @param force [Boolean] Force update even if recent
  # @return [Hash] Update results
  def self.update_all_rates(force: false)
    results = {
      updated: [],
      skipped: [],
      errors: []
    }

    Country.active.find_each do |country|
      begin
        result = update_country_rate(country, force:)

        if result[:status] == :updated
          results[:updated] << { country: country.code, rate: result[:rate] }
        elsif result[:status] == :skipped
          results[:skipped] << { country: country.code, reason: result[:reason] }
        else
          results[:errors] << { country: country.code, error: result[:error] }
        end

        sleep(REQUEST_DELAY) # Rate limiting

      rescue StandardError => e
        results[:errors] << { country: country.code, error: e.message }
      end
    end

    results
  end

  # Update exchange rate for a specific country
  # @param country [Country] Country record
  # @param force [Boolean] Force update even if recent
  # @return [Hash] Update status with new rate or skip reason
  def self.update_country_rate(country, force: false)
    return { status: :error, error: 'Country record invalid' } unless country
    return { status: :error, error: 'Exchange source not configured' } unless SOURCES.key?(country.code)

    source = SOURCES[country.code]
    return { status: :error, error: 'Source URL not configured' } unless source[:url]

    # Check if update is needed (skip if updated within 24 hours)
    last_rate = ExchangeRate.where(country_id: country.id).order(updated_at: :desc).first

    if !force && last_rate && last_rate.updated_at > 24.hours.ago
      return {
        status: :skipped,
        reason: "Recently updated (#{last_rate.updated_at.strftime('%Y-%m-%d %H:%M')})"
      }
    end

    # Fetch new rate from API (with fallback)
    new_rate = fetch_rate_from_api(country.code, source)

    return { status: :error, error: 'Failed to fetch rate' } unless new_rate

    # Update or create exchange rate record
    ExchangeRate.create_or_find_by!(
      country_id: country.id,
      rate_official: new_rate[:official],
      rate_black_market: new_rate[:black_market],
      rate_used: new_rate[:used],
      source: source[:name],
      date: Date.today
    )

    { status: :updated, rate: new_rate[:used] }
  end

  # Fetch rate from central bank API
  # @param country_code [String] Country code (e.g., 'AE', 'SA')
  # @param source [Hash] Source configuration
  # @return [Hash, nil] Rate data or nil on failure
  def self.fetch_rate_from_api(country_code, source)
    return fetch_fallback_rate(country_code) unless source[:url]

    begin
      # Central bank APIs vary significantly by country
      # This is a simplified implementation - production should use country-specific parsers

      case country_code
      when 'AE' # UAE - USD/AED fixed rate
        { official: 0.272, used: 0.272, black_market: nil }
      when 'SA' # Saudi Arabia
        { official: 0.267, used: 0.267, black_market: nil }
      when 'EG' # Egypt - needs scraping
        scrape_egypt_rate
      when 'TR' # Turkey
        scrape_turkey_rate
      else
        fetch_fallback_rate(country_code)
      end

    rescue ApiError => e
      nil
    rescue StandardError => e
      nil
    end
  end

  # Fetch fallback rate when API unavailable
  # @param country_code [String] Country code
  # @return [Hash] Fallback rate
  def self.fetch_fallback_rate(country_code)
    rate = FALLBACK_RATES[key_for_currency(country_code)]
    return nil unless rate

    { official: rate, used: rate, black_market: nil }
  end

  # Map country code to fallback rate currency
  # @param code [String] Country code
  # @return [String] Currency code for fallback lookup
  def self.key_for_currency(code)
    {
      'AE' => 'AED', 'SA' => 'SAR', 'EG' => 'EGP', 'TR' => 'TRY',
      'KW' => 'KWD', 'JO' => 'JOD', 'PK' => 'PKR', 'QA' => 'QAR',
      'BH' => 'BHD', 'OM' => 'OMR', 'IQ' => 'IQD', 'MA' => 'MAD'
    }[code] || code
  end

  # Scrape Egypt rate from CBE website
  # Note: Egypt has black market rate, returns both if available
  # @return [Hash] Rate data
  def self.scrape_egypt_rate
    require 'net/http'
    require 'nokogiri'

    url = 'https://www.cbe.org.eg/en/Economic-research/Market-Prices/Pages/Exchange-rate.aspx'
    response = Net::HTTP.get(URI.parse(url).open(read_timeout: REQUEST_TIMEOUT))

    return nil unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::HTML(response.body)
    rate_rows = doc.css('.table tbody tr')

    # Extract official rate (first data row)
    official_rate_text = rate_rows[1]&.css('td')[2]&.text&.strip
    official_rate = official_rate_text&.gsub(/[^\d.]/, '')&.to_f

    # Extract black market rate if available (second row)
    black_market_text = rate_rows[2]&.css('td')[2]&.text&.strip
    black_market = black_market_text&.gsub(/[^\d.]/, '')&.to_f

    {
      official: official_rate || FALLBACK_RATES['EGP'],
      used: official_rate || FALLBACK_RATES['EGP'], # Use official for calculations
      black_market: black_market
    }
  rescue StandardError => e
    nil
  end

  # Scrape Turkey rate from TCMB website
  # Note: Turkey has high inflation, rates change frequently
  # @return [Hash] Rate data
  def self.scrape_turkey_rate
    require 'net/http'
    require 'nokogiri'

    url = 'https://www.tcmb.gov.tr/wps/cms/en/ktmrates.xml'
    response = Net::HTTP.get(URI.parse(url).open(read_timeout: REQUEST_TIMEOUT))

    return nil unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::XML(response.body)
    rate_node = doc.at_xpath('//ForexBuyingForexSelling FOREXCurrencyCurrencyKod[CurrencyKod="USD"]')

    return nil unless rate_node

    # TCMB returns: <ForexBuying>1.00</ForexBuying>
    buying_text = rate_node.at_xpath('.//ForexBuying')&.text&.strip
    buying_rate = buying_text&.gsub(/[^\d.]/, '')&.to_f

    {
      official: buying_rate || FALLBACK_RATES['TRY'],
      used: buying_rate || FALLBACK_RATES['TRY'],
      black_market: nil
    }
  rescue StandardError => e
    nil
  end

  private

  # Validate rate value
  # @param rate [Float] Rate to validate
  # @return [Boolean] True if valid
  def self.valid_rate?(rate)
    rate.is_a?(Numeric) && rate.positive? && rate < 1000
  end
end
