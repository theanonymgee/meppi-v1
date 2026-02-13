#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Embedding API 엔드포인트 테스트 (다양한 경로 시도) ==='
puts "API Key: #{api_key[0..20]}..."
puts ''

test_urls = [
  ['https://api.z.ai/api/paas/v4', '/embeddings'],
  ['https://api.z.ai/api/paas/v4', '/embedding'],
  ['https://api.z.ai/api/paas/v4', '/api/embeddings'],
  ['https://api.z.ai/api/paas/v4/', '/embeddings'],
  ['https://open.bigmodel.cn/api/paas/v4', '/embeddings'],
  ['https://open.bigmodel.cn/api/paas/v4/', '/embeddings'],
]

test_urls.each do |base, path|
  conn = Faraday.new(base) do |f|
    f.request :json
    f.adapter Faraday.default_adapter
    f.options.timeout = 10
  end

  begin
    response = conn.post(path) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{api_key}"
      req.body = {
        model: 'embedding-2',
        input: 'test'
      }.to_json
    end

    puts "#{base}#{path}"
    puts "  Status: #{response.status}"

    if response.status == 200
      data = JSON.parse(response.body)
      puts "  ✅ SUCCESS! Dimensions: #{data['data'].first['embedding'].length}"
      break  # Stop on first success
    elsif response.status == 401
      puts "  ⚠️  Unauthorized - API Key issue"
    elsif response.status == 404
      puts "  ❌ Not Found"
    elsif response.status == 405
      puts "  ⚠️  Method Not Allowed"
    end
    puts ''
  rescue StandardError => e
    puts "#{base}#{path}"
    puts "  ❌ Error: #{e.message}"
    puts ''
  end
end
