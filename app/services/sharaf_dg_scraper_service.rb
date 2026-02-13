# frozen_string_literal: true

# Sharaf DG Scraper Service - Electronics retailer data collection
# Single Responsibility: Fetch product listings from Sharaf DG
# Vibe Coding: Multi-country support, error handling, rate limiting

class SharafDgScraperService
  REQUEST_TIMEOUT = 60  # Increased from 30s
  REQUEST_DELAY = 3 # Rate limiting between requests (increased from 2s)

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15'
  ].freeze

  # Sharaf DG country-specific domains
  DOMAINS = {
    'AE' => 'https://www.sharafdg.com',
    'SA' => 'https://www.sharafdg.com',
    'QA' => 'https://www.sharafdg.com'
  }.freeze

  class ScrapingError < StandardError; end
  class BlockedError < StandardError; end

  # Fetch phone listings for a brand
  # @param brand [String] Brand name (samsung, apple, xiaomi, etc.)
  # @param country_code [String] Country code (AE, SA, QA)
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
      # Graceful skip - log and return empty instead of raising
      puts "    ⚠️  SharafDG blocked (403) for #{country_code} - skipping gracefully"
      []
    when 404
      []
    else
      raise ScrapingError, "HTTP #{response.code.to_i}: #{response.body[0..200]}"
    end

  rescue ScrapingError, BlockedError => e
    raise # Re-raise for caller handling
  rescue StandardError => e
    raise ScrapingError, "Request failed: #{e.message}"
  end

  # Build search URL for brand and country
  # @param brand [String] Brand name
  # @param country_code [String] Country code
  # @param page [Integer] Page number
  # @return [String] Full URL
  def self.build_search_url(brand, country_code, page)
    domain = DOMAINS[country_code] || DOMAINS['AE']

    # Sharaf DG search URL pattern: https://www.sharafdg.com/ae/search?q=samsung
    "#{domain}/#{country_code.downcase}/search?q=#{uri_encode(brand)}&page=#{page}"
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
    cards = doc.css('.product-item, .item')

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
    title_el = card.at_css('.product-title, h3, h2')
    title = title_el&.text&.strip
    return nil unless title

    # Brand validation
    return nil unless title.downcase.include?(brand.downcase)

    # Price - extract numeric price
    price_el = card.at_css('.price, .price-text')
    price = extract_price(price_el&.text)

    # URL
    link_el = card.at_css('a')
    detail_url = link_el&.[]('href')
    full_url = ensure_absolute_url(detail_url, country_code)

    # Image
    image_el = card.at_css('img, .product-image img')
    image_url = image_el&.[]('src')

    # Stock status
    stock_el = card.at_css('.stock-status, [data-stock]')
    in_stock = stock_el ? stock_el['data-stock'] == 'true' : true

    # Currency by country
    currency = currency_for_country(country_code)

    {
      title:,
      brand: brand.capitalize,
      price_local: price,
      price_usd: convert_to_usd(price, currency),
      currency:,
      url: full_url,
      image_url:,
      in_stock:,
      source: 'Sharaf DG',
      trade_type: 'sale',
      category: 'mobile-phones',
      country_code: country_code
    }
  end

  # Ensure URL is absolute
  # @param url [String] URL to check
  # @param country_code [String] Country code
  # @return [String] Absolute URL
  def self.ensure_absolute_url(url, country_code)
    return url if url.start_with?('http')

    base_domain = DOMAINS[country_code] || DOMAINS['AE']
    url.start_with?('/') ? "#{base_domain}#{url}" : url
  end

  # Get currency for country code
  # @param country_code [String] Country code
  # @return [String] Currency code
  def self.currency_for_country(country_code)
    {
      'AE' => 'AED', 'SA' => 'SAR', 'QA' => 'QAR'
    }[country_code] || 'AED'
  end

  # Extract price from text (AED 3,499.00)
  # @param price_text [String] Price text
  # @return [Float, nil] Extracted price
  def self.extract_price(price_text)
    return nil unless price_text

    # Remove currency symbol, commas, extract first number
    cleaned = price_text.gsub(/[AED|SAR|QAR\s,]/, '')
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
      'AED' => 'AE', 'SAR' => 'SA', 'QAR' => 'QA'
    }[code] || code
  end

  # Fallback exchange rates for common currencies (when rate unavailable)
  # @param code [String] Currency code
  # @return [Float] Fallback rate to USD
  def self.FALLBACK_RATE(code)
    {
      'AED' => 0.272, 'SAR' => 0.267, 'QAR' => 0.275
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

  # Encode URL component
  # @param text [String] Text to encode
  # @return [String] Encoded text
  def self.uri_encode(text)
    ERB::Util.url_encode(text)
  end
end
