# SerpAPI 기반 스크래퍼 - Google Shopping에서 가격 수집
# Amazon.ae 직접 스크래핑 대신 사용

require 'net/http'
require 'uri'
require 'json'

class SerpApiScraperService
  BASE_URL = 'https://serpapi.com/search.json'
  API_KEY = ENV.fetch('SERPAPI_KEY')

  # 검색해서 Google Shopping 결과 가져오기
  def self.search_shopping(query:, country: 'ae', limit: 20)
    uri = URI(BASE_URL)
    params = {
      engine: 'google_shopping',
      q: query,
      gl: country.upcase,
      hl: 'en',
      api_key: API_KEY
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      results = data['shopping_results'] || []
      results.first(limit).map { |r| parse_result(r) }
    else
      puts "SerpAPI error: #{response.code}"
      []
    end
  rescue StandardError => e
    puts "SerpAPI error: #{e.message}"
    []
  end

  # 브랜드별 스마트폰 검색
  def self.fetch_phones(brand:, country: 'ae')
    query = "#{brand} smartphone #{country == 'ae' ? 'UAE' : country.upcase}"
    search_shopping(query:, country:)
  end

  private

  def self.parse_result(result)
    {
      title: result['title'],
      price: result['price'],
      price_usd: result['extracted_price'],
      source: result['source'],
      rating: result['rating'],
      reviews: result['reviews'],
      thumbnail: result['thumbnail'],
      product_id: result['product_id'],
      link: result['product_link']
    }
  end
end
