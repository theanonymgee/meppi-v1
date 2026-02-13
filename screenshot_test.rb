#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

SERVER_URL = "http://localhost:3000"
SCREENSHOT_DIR = "qa_screenshots"
Dir.mkdir(SCREENSHOT_DIR) unless Dir.exist?(SCREENSHOT_DIR)

# Test results
results = {
  passed: 0,
  failed: 0,
  errors: []
}

# Test endpoints
endpoints = [
  { path: "/", name: "Root Path" },
  { path: "/dashboard", name: "Dashboard Home" },
  { path: "/channel-comparison", name: "Channel Comparison" },
  { path: "/competition", name: "Competition Index" },
  { path: "/promotion", name: "Promotion Index" },
  { path: "/regional-price", name: "Regional Price" },
  { path: "/api/v1/navigation", name: "API Navigation" },
  { path: "/health", name: "Health Check" }
]

puts "🧪 Starting QA Test Suite"
puts "=" * 50

# Test each endpoint
endpoints.each do |endpoint|
  puts "\n📍 Testing: #{endpoint[:name]} (#{endpoint[:path]})"

  begin
    uri = URI("#{SERVER_URL}#{endpoint[:path]}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)

    # Set timeout
    http.read_timeout = 10

    response = http.request(request)

    status = response.code
    puts "   Status: #{status}"

    if status == "200"
      puts "   ✅ PASSED"
      results[:passed] += 1

      # Save response for inspection
      filename = "#{SCREENSHOT_DIR}/#{endpoint[:name].downcase.gsub(/\s+/, '_')}_#{status}.html"
      File.write(filename, response.body) if response.body

    elsif status == "404"
      puts "   ❌ FAILED - 404 Not Found"
      results[:failed] += 1
      results[:errors] << "#{endpoint[:name]}: 404 Not Found"

    elsif status == "500"
      puts "   ❌ FAILED - 500 Server Error"
      results[:failed] += 1
      results[:errors] << "#{endpoint[:name]}: 500 Server Error"

      # Save error response for debugging
      filename = "#{SCREENSHOT_DIR}/#{endpoint[:name].downcase.gsub(/\s+/, '_')}_#{status}.html"
      File.write(filename, response.body) if response.body

    else
      puts "   ⚠️  UNEXPECTED - #{status}"
      results[:failed] += 1
      results[:errors] << "#{endpoint[:name]}: Unexpected status #{status}"
    end

  rescue => e
    puts "   ❌ ERROR: #{e.message}"
    results[:failed] += 1
    results[:errors] << "#{endpoint[:name]}: #{e.message}"
  end
end

# Test API endpoint
puts "\n🔍 Testing API: Semantic Search"
begin
  uri = URI("#{SERVER_URL}/api/v1/semantic_search")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = { query: "iPhone 15" }.to_json

  response = http.request(request)

  status = response.code
  puts "   Status: #{status}"

  if status == "200"
    puts "   ✅ PASSED"
    results[:passed] += 1
  else
    puts "   ❌ FAILED"
    results[:failed] += 1
    results[:errors] << "Semantic API: Status #{status}"
  end

rescue => e
  puts "   ❌ ERROR: #{e.message}"
  results[:failed] += 1
  results[:errors] << "Semantic API: #{e.message}"
end

# Summary
puts "\n" + "=" * 50
puts "📊 TEST SUMMARY"
puts "=" * 50
puts "✅ Passed: #{results[:passed]}"
puts "❌ Failed: #{results[:failed]}"
puts "📝 Errors: #{results[:errors].count}"

if results[:errors].any?
  puts "\n🔴 ERRORS FOUND:"
  results[:errors].each { |error| puts "   - #{error}" }
end

puts "\n📁 Screenshots saved to: #{SCREENSHOT_DIR}/"
puts "🎯 Test completed at: #{Time.now}"