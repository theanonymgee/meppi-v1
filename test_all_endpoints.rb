#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Embedding API 전체 엔드포인트 테스트 ==='
puts "API Key: #{api_key[0..20]}..."
puts ''

# 모든 조합 테스트
test_cases = [
  # [Base URL, Endpoint, Description]
  ['https://open.bigmodel.cn/api/paas/v4', '/embeddings', 'Zhipu official (open.bigmodel.cn)'],
  ['https://open.bigmodel.cn/api/paas/v4', '/api/embeddings', 'Zhipu with /api prefix'],
  ['https://api.z.ai/api/paas/v4', '/embeddings', 'Z.ai international'],
  ['https://api.z.ai/api/paas/v4', '/api/embeddings', 'Z.ai with /api prefix'],
  ['https://api.z.ai', '/api/paas/v4/embeddings', 'Full path embedding'],
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
      puts "  ✅ SUCCESS! Dimensions: #{data['data']&.first&.dig('embedding')&.length || 'N/A'}"
      puts "  Model: #{data['model']}"
      puts "  Full Response:"
      puts "  #{JSON.pretty_generate(data).lines.map { |l| '  ' + l }.join}"
      break  # Stop on first success
    elsif response.status == 401
      puts "  ⚠️  Unauthorized"
    elsif response.status == 404
      puts "  ❌ Not Found"
    elsif response.status == 405
      puts "  ⚠️  Method Not Allowed"
    else
      body = response.body[0..200] rescue ''
      puts "  Response: #{body}"
    end
    puts ''
  rescue StandardError => e
    puts "[#{desc}]"
    puts "  URL: #{base_url}#{endpoint}"
    puts "  ❌ Error: #{e.class.name} - #{e.message}"
    puts ''
  end
end
