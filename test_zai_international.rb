#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.ai International API 테스트 ==='
puts ''

# 원래 base URL로 시도
test_cases = [
  ['https://api.z.ai/api/paas/v4', '/api/embeddings', 'Z.ai with /api prefix'],
  ['https://api.z.ai/api/paas/v4', '/embeddings', 'Z.ai without /api'],
  ['https://api.z.ai', '/api/paas/v4/api/embeddings', 'Full path'],
]

test_cases.each do |base_url, endpoint, desc|
  conn = Faraday.new(base_url) do |f|
    f.request :json
    f.adapter Faraday.default_adapter
    f.options.timeout = 10
  end

  begin
    response = conn.post(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{api_key}"
      req.body = {
        model: 'embedding-2',
        input: 'test'
      }.to_json
    end

    puts "[#{desc}]"
    puts "  URL: #{base_url}#{endpoint}"
    puts "  Status: #{response.status}"

    if response.status == 200
      data = JSON.parse(response.body)
      if data['success'] == false
        puts "  API Error: #{data['msg']}"
      else
        puts "  ✅ SUCCESS! Dimensions: #{data['data']&.first&.dig('embedding')&.length || 'N/A'}"
        puts "  Full Response:"
        puts "  #{JSON.pretty_generate(data).lines.map { |l| '  ' + l }.join}"
        break
      end
    elsif response.status == 401
      puts "  ⚠️  Unauthorized"
    elsif response.status == 404
      puts "  ❌ Not Found"
    else
      puts "  Response: #{response.body[0..200]}"
    end
    puts ''
  rescue StandardError => e
    puts "[#{desc}]"
    puts "  URL: #{base_url}#{endpoint}"
    puts "  ❌ Error: #{e.class.name} - #{e.message}"
    puts ''
  end
end
