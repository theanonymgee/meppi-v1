# frozen_string_literal: true

require 'cgi'

# Amazon.ae Scraper Service - UAE Amazon product data collection
# Single Responsibility: Fetch product listings from Amazon.ae
# Vibe Coding: Error handling, rate limiting, no hardcoded values

class AmazonAeScraperService
  BASE_URL = ENV.fetch('AMAZON_AE_URL', 'https://www.amazon.ae')
  REQUEST_TIMEOUT = 60
  REQUEST_DELAY = 5 # Rate limiting between requests (increased from 3)
  MAX_RETRIES = 2

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  ].freeze

  class ScrapingError < StandardError; end
  class BlockedError < StandardError; end

  # Fetch phone listings for a brand
  # @param brand [String] Brand name (samsung, apple, xiaomi, etc.)
  # @param page [Integer] Page number (default: 1)
  # @return [Array<Hash>] Product listings
  def self.fetch_listings(brand:, page: 1)
    sleep(REQUEST_DELAY) # Rate limiting

    url = build_search_url(brand, page)
    
    retries = 0
    response = nil
    
    loop do
      response = http_get(url)
      break if response.code.to_i != 503 || retries >= MAX_RETRIES
      retries += 1
      puts "    ⚠️  Amazon.ae 503 - retry #{retries}/#{MAX_RETRIES} after #{REQUEST_DELAY * 2}s"
      sleep(REQUEST_DELAY * 2)
    end

    case response.code.to_i
    when 200
      parse_html(response.body, brand)
    when 403
      puts "    ⚠️  Amazon.ae blocked (403) - skipping"
      []
    when 404
      []
    when 503
      puts "    ⚠️  Amazon.ae 503 - max retries reached, skipping"
      []
    else
      puts "    ⚠️  Amazon.ae HTTP #{response.code.to_i} - skipping"
      []
    end

  rescue Net::ReadTimeout, Net::OpenTimeout => e
    puts "    ⚠️  Amazon.ae timeout - skipping"
    []
  rescue StandardError => e
    puts "    ⚠️  Amazon.ae error: #{e.message} - skipping"
    []
  end

  # Build search URL for brand
  # @param brand [String] Brand name
  # @param page [Integer] Page number
  # @return [String] Full URL
  def self.build_search_url(brand, page)
    "#{BASE_URL}/s?k=#{CGI.escape(brand)}&page=#{page}"
  end

  # Parse HTML response
  # @param html_body [String] HTML content
  # @param brand [String] Brand name
  # @return [Array<Hash>] Parsed product data
  def self.parse_html(html_body, brand)
    # Force UTF-8 encoding to avoid incompatible encoding errors
    html_body = html_body.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    doc = Nokogiri::HTML(html_body)
    cards = doc.css('.s-result-item[data-component-type]')

    cards.map do |card|
      extract_product_info(card, brand)
    end.compact
  end

  # Extract product information from card element
  # @param card [Nokogiri::XML::Element] Product card
  # @param brand [String] Brand name
  # @return [Hash, nil] Product data
  def self.extract_product_info(card, brand)
    # Title - FIXED: use .a-text-normal or h2 span (not h2 a.s-title-medium)
    title_el = card.at_css('.a-text-normal') || card.at_css('h2 span')
    title = title_el&.text&.strip
    return nil unless title

    # Brand validation
    return nil unless title.downcase.include?(brand.downcase)

    # Price - FIXED: use .a-price .a-offscreen for full price
    price_el = card.at_css('.a-price .a-offscreen')
    price = extract_price(price_el&.text)

    # URL
    link_el = card.at_css('h2 a') || card.at_css('a')
    detail_url = link_el&.[]('href')
    full_url = detail_url.to_s.empty? ? nil : "#{BASE_URL}#{detail_url}"

    # Image
    image_el = card.at_css('.s-product-image img') || card.at_css('img')
    image_url = image_el&.[]('src')

    # Storage/Specs extraction
    specs = {}
    storage_el = card.at_css('.a-section.a-spacing-base-small .a-span:last')
    specs[:storage] = storage_el&.text&.strip if storage_el

    {
      title:,
      brand: brand.capitalize,
      price_local: price,
      price_usd: convert_to_usd(price, 'AED'),
      currency: 'AED',
      url: full_url,
      image_url:,
      specs:,
      source: 'Amazon.ae',
      trade_type: 'sale',
      category: 'mobile-phones'
    }
  end

  # Extract price from text (AED 3,499.00)
  # @param price_text [String] Price text
  # @return [Float, nil] Extracted price
  def self.extract_price(price_text)
    return nil unless price_text

    # Remove currency symbol and commas, convert to float
    cleaned = price_text.gsub(/[AED\s,]/, '')
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
      'TRY' => 'TR', 'KWD' => 'KW', 'QAR' => 'QA',
      'BHD' => 'BH', 'OMR' => 'OM', 'IQD' => 'IQ'
    }[code] || code
  end

  # Fallback exchange rates for common currencies (when rate unavailable)
  # @param code [String] Currency code
  # @return [Float] Fallback rate to USD
  def self.FALLBACK_RATE(code)
    {
      'AED' => 0.272, 'SAR' => 0.267, 'EGP' => 0.0204,
      'TRY' => 0.030, 'KWD' => 3.25, 'QAR' => 0.275,
      'BHD' => 2.65, 'OMR' => 2.60, 'IQD' => 0.00076
    }[code] || 1.0
  end

  private

  # HTTP GET with error handling
  # @param url [String] URL to fetch
  # @return [Net::HTTPResponse] Response
  def self.http_get(url)
    uri = URI.parse(url)

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENTS.sample
    request['Accept-Language'] = 'en-US,en;q=0.9'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    request['Accept-Encoding'] = 'gzip, deflate, br'
    request['Connection'] = 'keep-alive'
    request['Upgrade-Insecure-Requests'] = '1'
    request['Cache-Control'] = 'max-age=0'
    request['Referer'] = 'https://www.amazon.ae/'

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      http.request(request)
    end

    response
  rescue StandardError => e
    raise ScrapingError, "HTTP request failed: #{e.message}"
  end

  # Encode URL component
  # @param text [String] Text to encode
  # @return [String] Encoded text
  def self.uri_encode(text)
    ERB::Util.url_encode(text)
  end
end
