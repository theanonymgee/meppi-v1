# frozen_string_literal: true

# Noon Scraper Service - Multi-country Noon product data collection
# Single Responsibility: Fetch product listings from Noon (UAE, KSA, Egypt)
# Vibe Coding: Error handling, rate limiting, country-specific URLs

class NoonScraperService
  REQUEST_TIMEOUT = 45  # Reduced from 120s - reasonable timeout
  REQUEST_DELAY = 2 # Rate limiting between requests

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  ].freeze

  # Noon country-specific domains
  DOMAINS = {
    'AE' => 'https://www.noon.com',
    'SA' => 'https://www.noon.com',
    'EG' => 'https://www.noon.com'
  }.freeze

  # Country codes for URLs
  COUNTRY_PARAMS = {
    'AE' => '_ae-en',
    'SA' => '_sa-en',
    'EG' => '_eg-en'
  }.freeze

  class ScrapingError < StandardError; end
  class BlockedError < StandardError; end

  # Fetch phone listings for a brand and country
  # @param brand [String] Brand name (samsung, apple, xiaomi, etc.)
  # @param country_code [String] Country code (AE, SA, EG)
  # @param page [Integer] Page number (default: 1)
  # @return [Array<Hash>] Product listings
  def self.fetch_listings(brand:, country_code: 'AE', page: 1)
    sleep(REQUEST_DELAY) # Rate limiting

    url = build_search_url(brand, country_code, page)
    response = http_get(url, country_code)

    case response.code.to_i
    when 200
      parse_html(response.body, brand, country_code)
    when 403
      puts "    ⚠️  Noon blocked (403) for #{country_code} - skipping"
      []
    when 404
      []
    else
      puts "    ⚠️  Noon HTTP #{response.code.to_i} for #{country_code} - skipping"
      []
    end

  rescue Net::ReadTimeout, Net::OpenTimeout => e
    puts "    ⚠️  Noon timeout for #{country_code} - skipping"
    []
  rescue StandardError => e
    puts "    ⚠️  Noon error for #{country_code}: #{e.message} - skipping"
    []
  end

  # Build search URL for brand and country
  # @param brand [String] Brand name
  # @param country_code [String] Country code
  # @param page [Integer] Page number
  # @return [String] Full URL
  def self.build_search_url(brand, country_code, page)
    domain = DOMAINS[country_code] || DOMAINS['AE']
    param = COUNTRY_PARAMS[country_code] || COUNTRY_PARAMS['AE']

    # Noon search URL pattern: https://www.noon.com/uae-en/smartphones-{brand}?page=1
    "#{domain}/#{param}/smartphones-#{brand.downcase}?page=#{page}"
  end

  # Parse HTML response
  # @param html_body [String] HTML content
  # @param brand [String] Brand name
  # @param country_code [String] Country code
  # @return [Array<Hash>] Parsed product data
  def self.parse_html(html_body, brand, country_code)
    # Force UTF-8 encoding to avoid incompatible encoding errors
    html_body = html_body.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    doc = Nokogiri::HTML(html_body)
    cards = doc.css('.product-cell')

    cards.map do |card|
      extract_product_info(card, brand, country_code)
    end.compact
  end

  # Extract product information from card element
  # @param card [Nokogiri::XML::Element] Product card
  # @param brand [String] Brand name
  # @param country_code [String] Country code
  # @return [Hash, nil] Product data
  def self.extract_product_info(card, brand, country_code)
    # Title
    title_el = card.at_css('a[href] h3')
    title = title_el&.text&.strip
    return nil unless title

    # Brand validation
    return nil unless title.downcase.include?(brand.downcase)

    # Price
    price_el = card.at_css('.price')
    price = extract_price(price_el&.text)

    # URL
    link_el = card.at_css('a[href]')
    detail_url = link_el&.[]('href')

    # Image
    image_el = card.at_css('img')
    image_url = image_el&.[]('src')

    # Currency by country
    currency = currency_for_country(country_code)

    {
      title:,
      brand: brand.capitalize,
      price_local: price,
      price_usd: convert_to_usd(price, currency),
      currency:,
      url: detail_url,
      image_url:,
      source: 'Noon',
      trade_type: 'sale',
      category: 'mobile-phones',
      country_code: country_code
    }
  end

  # Get currency for country code
  # @param country_code [String] Country code
  # @return [String] Currency code
  def self.currency_for_country(country_code)
    {
      'AE' => 'AED', 'SA' => 'SAR', 'EG' => 'EGP'
    }[country_code] || 'AED'
  end

  # Extract price from text (AED 3,499)
  # @param price_text [String] Price text
  # @return [Float, nil] Extracted price
  def self.extract_price(price_text)
    return nil unless price_text

    # Remove currency symbol and commas, handle different formats
    cleaned = price_text.gsub(/[AED|SAR|EGP\s,]/, '')
                       .gsub(/[,.]/, '')
    cleaned.to_f
  end

  # Convert local currency to USD
  # @param price [Float] Local price
  # @param currency [String] Currency code
  # @return [Float] Price in USD
  def self.convert_to_usd(price, currency)
    return price unless price

    # Get exchange rate for currency
    rate = ExchangeRate.where(country_id: Country.find_by(code: currency_code(currency))).order(date: :desc).first

    usd_price = if rate
                   price * rate.rate_used
                 else
                   price * FALLBACK_RATE(currency)
                 end

    usd_price&.round(2)
  end

  # Get currency code from country code
  # @param code [String] Country/Currency code
  # @return [String] Currency code
  def self.currency_code(code)
    {
      'AED' => 'AE', 'SAR' => 'SA', 'EGP' => 'EG',
      'KWD' => 'KW', 'QAR' => 'QA', 'BHD' => 'BH'
    }[code] || code
  end

  # Fallback exchange rates for common currencies (when rate unavailable)
  # @param code [String] Currency code
  # @return [Float] Fallback rate to USD
  def self.FALLBACK_RATE(code)
    {
      'AED' => 0.272, 'SAR' => 0.267, 'EGP' => 0.0204,
      'KWD' => 3.25, 'QAR' => 0.275, 'BHD' => 2.65
    }[code] || 1.0
  end

  private

  # HTTP GET with error handling
  # @param url [String] URL to fetch
  # @param country_code [String] Country code for Referer
  # @return [Net::HTTPResponse] Response
  def self.http_get(url, country_code = 'AE')
    uri = URI.parse(url)

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENTS.sample
    request['Accept-Language'] = 'en-US,en;q=0.9'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9'

    # Add country-specific referer for better anti-bot handling
    domain = DOMAINS[country_code] || DOMAINS['AE']
    request['Referer'] = "#{domain}/"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      http.request(request)
    end

    response
  rescue StandardError => e
    raise ScrapingError, "HTTP request failed: #{e.message}"
  end
end
