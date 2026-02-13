#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script for Amazon.ae scraper
# Run: bundle exec rails runner debug_amazon.rb

require 'net/http'
require 'uri'
require 'nokogiri'

USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
].freeze

def http_get(url)
  uri = URI.parse(url)
  
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = USER_AGENTS.sample
  request['Accept-Language'] = 'en-US,en;q=0.9'
  request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9'
  
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: 30) do |http|
    http.request(request)
  end
  
  response
rescue StandardError => e
  puts "HTTP error: #{e.message}"
  nil
end

# Test URL
url = 'https://www.amazon.ae/s?k=samsung'
puts "=" * 60
puts "Testing Amazon.ae: #{url}"
puts "=" * 60

response = http_get(url)

if response
  puts "\nResponse Code: #{response.code}"
  puts "Response Content-Type: #{response['content-type']}"
  
  doc = Nokogiri::HTML(response.body)
  
  # Debug 1: Check for product containers
  puts "\n" + "-" * 60
  puts "DEBUG 1: Product Container Tests"
  puts "-" * 60
  
  # Current selector
  cards_v1 = doc.css('.s-result-item[data-component-type]')
  puts "  .s-result-item[data-component-type]: #{cards_v1.count} items"
  
  # Alternative selectors
  cards_v2 = doc.css('[data-component-type="s-search-result"]')
  puts "  [data-component-type='s-search-result']: #{cards_v2.count} items"
  
  cards_v3 = doc.css('.s-result-item')
  puts "  .s-result-item (all): #{cards_v3.count} items"
  
  cards_v4 = doc.css('[data-asin]')
  puts "  [data-asin]: #{cards_v4.count} items"
  
  # Debug 2: Title selectors
  puts "\n" + "-" * 60
  puts "DEBUG 2: Title Selector Tests"
  puts "-" * 60
  
  sample_card = cards_v1.first
  if sample_card
    # Current selector
    title_v1 = sample_card.at_css('h2 a.s-title-medium')
    puts "  h2 a.s-title-medium: #{title_v1&.text&.strip || 'NOT FOUND'}"
    
    # Alternative selectors
    title_v2 = sample_card.at_css('h2 a span')
    puts "  h2 a span: #{title_v2&.text&.strip || 'NOT FOUND'}"
    
    title_v3 = sample_card.at_css('h2 .a-text-medium')
    puts "  h2 .a-text-medium: #{title_v3&.text&.strip || 'NOT FOUND'}"
    
    title_v4 = sample_card.at_css('.a-text-normal')
    puts "  .a-text-normal: #{title_v4&.text&.strip || 'NOT FOUND'}"
    
    title_v5 = sample_card.at_css('h2 span')
    puts "  h2 span: #{title_v5&.text&.strip || 'NOT FOUND'}"
    
    # Debug 3: Price selectors
    puts "\n" + "-" * 60
    puts "DEBUG 3: Price Selector Tests"
    puts "-" * 60
    
    price_v1 = sample_card.at_css('.a-price-whole')
    puts "  .a-price-whole: #{price_v1&.text&.strip || 'NOT FOUND'}"
    
    price_v2 = sample_card.at_css('.a-price .a-offscreen')
    puts "  .a-price .a-offscreen: #{price_v2&.text&.strip || 'NOT FOUND'}"
    
    price_v3 = sample_card.at_css('.a-price')
    puts "  .a-price: #{price_v3&.text&.strip || 'NOT FOUND'}"
    
    # Debug 4: Check if CAPTCHA or anti-bot page
    puts "\n" + "-" * 60
    puts "DEBUG 4: Anti-bot Check"
    puts "-" * 60
    
    captcha = doc.at_css('#captchacharacters')
    puts "  CAPTCHA detected: #{captcha ? 'YES' : 'NO'}"
    
    robot_check = doc.text.include?('Robot Check') || doc.text.include?('Type the characters')
    puts "  Robot check text: #{robot_check ? 'YES' : 'NO'}"
    
    # Save sample HTML for inspection
    puts "\n" + "-" * 60
    puts "Sample HTML (first card):"
    puts "-" * 60
    puts sample_card.to_html[0..1000] if sample_card
  else
    puts "  No cards found to test"
    
    # Check page content
    puts "\n" + "-" * 60
    puts "Page body sample (first 2000 chars):"
    puts "-" * 60
    puts response.body[0..2000]
  end
else
  puts "Failed to get response"
end

puts "\n" + "=" * 60
puts "Debug Complete"
puts "=" * 60
