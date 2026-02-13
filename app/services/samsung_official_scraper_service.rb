# frozen_string_literal: true

# Samsung Official Scraper Service - Samsung official store data collection
# Single Responsibility: Fetch product listings from Samsung official stores
# Vibe Coding: Multi-country support, error handling, rate limiting

class SamsungOfficialScraperService
  REQUEST_TIMEOUT = 30
  REQUEST_DELAY = 2 # Rate limiting between requests

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  ].freeze

  # Samsung country-specific domains
  DOMAINS = {
    'AE' => 'https://www.samsung.com/ae',
    'SA' => 'https://www.samsung.com/sa',
    'EG' => 'https://www.samsung.com/eg',
    'JO' => 'https://www.samsung.com/jo',
    'KW' => 'https://www.samsung.com/kw',
    'QA' => 'https://www.samsung.com/qa',
    'BH' => 'https://www.samsung.com/bh',
    'OM' => 'https://www.samsung.com/om',
    'MA' => 'https://www.samsung.com/ma_en/home'
  }.freeze

  # Country paths for Samsung URLs
  COUNTRY_PATHS = {
    'AE' => 'ae', 'SA' => 'sa', 'EG' => 'eg',
    'JO' => 'jo', 'KW' => 'kw', 'QA' => 'qa',
    'BH' => 'bh', 'OM' => 'om', 'MA' => 'ma_en'
  }.freeze

  class ScrapingError < StandardError; end
  class BlockedError < StandardError; end

  # Fetch phone listings for a model and country
  # @param model [String] Model name (galaxy-s24, etc.)
  # @param country_code [String] Country code (AE, SA, EG, etc.)
  # @param page [Integer] Page number (default: 1)
  # @return [Array<Hash>] Product listings
  def self.fetch_listings(model:, country_code: 'AE', page: 1)
    sleep(REQUEST_DELAY) # Rate limiting

    url = build_search_url(model, country_code, page)
    response = http_get(url, country_code)

    case response.code.to_i
    when 200
      parse_html(response.body, model, country_code)
    when 403
      raise BlockedError, "Blocked by anti-bot: #{url}"
    when 404
      []
    else
      raise ScrapingError, "HTTP #{response.code.to_i}: #{response.body}"
    end

  rescue ScrapingError, BlockedError => e
    raise # Re-raise for caller handling
  rescue StandardError => e
    raise ScrapingError, "Request failed: #{e.message}"
  end

  # Build search URL for model and country
  # @param model [String] Model name (e.g., 'galaxy-s24-ultra')
  # @param country_code [String] Country code
  # @param page [Integer] Page number
  # @return [String] Full URL
  def self.build_search_url(model, country_code, page)
    domain = DOMAINS[country_code] || DOMAINS['AE']
    path = COUNTRY_PATHS[country_code] || COUNTRY_PATHS['AE']

    # Samsung search URL pattern: https://www.samsung.com/ae/smartphones/galaxy-s24
    sanitized_model = model.downcase.gsub(/\s+/, '-').gsub('_', '-')
    "#{domain}/smartphones/#{sanitized_model}?page=#{page}"
  end

  # Parse HTML response
  # @param html_body [String] HTML content
  # @param model [String] Model name for validation
  # @param country_code [String] Country code
  # @return [Array<Hash>] Parsed product data
  def self.parse_html(html_body, model, country_code)
    doc = Nokogiri::HTML(html_body)

    # Samsung product grid items
    cards = doc.css('.product-card, .card-wrapper, .product-item')

    cards.map do |card|
      extract_product_info(card, model, country_code)
    end.compact
  end

  # Extract product information from card element
  # @param card [Nokogiri::XML::Element] Product card
  # @param model [String] Model name for validation
  # @param country_code [String] Country code
  # @return [Hash, nil] Product data
  def self.extract_product_info(card, model, country_code)
    # Title/Model
    title_el = card.at_css('h1, h2, h3, .product-name')
    title = title_el&.text&.strip
    return nil unless title

    # Model validation - only return if matches requested model
    return nil unless title.downcase.include?(model.downcase.gsub(/-/, '').gsub(/\s+/, ' '))

    # Price
    price_el = card.at_css('.price, .price-text, [data-testid="price"]')
    price = extract_price(price_el&.text)

    # URL
    link_el = card.at_css('a')
    detail_url = link_el&.[]('href')
    full_url = detail_url.empty? ? nil : ensure_absolute_url(detail_url, country_code)

    # Image
    image_el = card.at_css('img, .product-image img')
    image_url = image_el&.[]('src')

    # Storage variants (color, capacity)
    storage_variants = extract_storage_variants(card)

    # Currency by country
    currency = currency_for_country(country_code)

    {
      title:,
      brand: 'Samsung',
      model: title,
      price_local: price,
      price_usd: convert_to_usd(price, currency),
      currency:,
      url: full_url,
      image_url:,
      specs: { storage: storage_variants },
      source: 'Samsung Official',
      trade_type: 'sale',
      category: 'mobile-phones',
      country_code: country_code
    }
  end

  # Extract storage variants (color, capacity) from product card
  # @param card [Nokogiri::XML::Element] Product card
  # @return [Hash] Storage variants
  def self.extract_storage_variants(card)
    variants = {}

    # Look for color selector buttons
    color_buttons = card.css('.color-selector button, [data-color]')
    color_buttons.each do |btn|
      color = btn['data-color']&.strip
      variants[color] = 1 if color
    end

    # Look for capacity/storage selector
    capacity_buttons = card.css('.storage-selector button, [data-storage]')
    capacity_buttons.each do |btn|
      storage = btn['data-storage']&.strip
      variants[storage] = 1 if storage
    end

    variants
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
      'AE' => 'AED', 'SA' => 'SAR', 'EG' => 'EGP',
      'JO' => 'JOD', 'KW' => 'KWD', 'QA' => 'QAR',
      'BH' => 'BHD', 'OM' => 'OMR', 'MA' => 'MAD'
    }[country_code] || 'AED'
  end

  # Extract price from text (AED 3,499.00)
  # @param price_text [String] Price text
  # @return [Float, nil] Extracted price
  def self.extract_price(price_text)
    return nil unless price_text

    # Remove currency symbol, commas, extract first number
    cleaned = price_text.gsub(/[AED|SAR|EGP|JOD|KWD|QAR|BHD|OMR|MAD\s,]/, '')
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
      'JO' => 'JO', 'KW' => 'KW', 'QA' => 'QA',
      'BH' => 'BH', 'OM' => 'OM', 'MA' => 'MA'
    }[code] || code
  end

  # Fallback exchange rates for common currencies (when rate unavailable)
  # @param code [String] Currency code
  # @return [Float] Fallback rate to USD
  def self.FALLBACK_RATE(code)
    {
      'AED' => 0.272, 'SAR' => 0.267, 'EGP' => 0.0204,
      'KWD' => 3.25, 'QAR' => 0.275, 'BHD' => 2.65,
      'JOD' => 1.41, 'OMR' => 2.60, 'MAD' => 0.099
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
