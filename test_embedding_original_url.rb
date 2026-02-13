#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

# Test with ORIGINAL base URL but CORRECTED model name
ENV['ZAI_API_BASE_URL'] = 'https://api.z.ai/api/paas/v4'

base_url = ENV.fetch('ZAI_API_BASE_URL')
api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Embedding API 테스트 (원래 URL + 수정된 모델명) ==='
puts "Base URL: #{base_url}"
puts "API Key: #{api_key[0..20]}..."
puts "Model: embedding-2 (수정됨)"
puts ''

# Test /embeddings endpoint
conn = Faraday.new(base_url) do |f|
  f.request :json
  f.adapter Faraday.default_adapter
  f.options.timeout = 30
end

response = conn.post('/embeddings') do |req|
  req.headers['Content-Type'] = 'application/json'
  req.headers['Authorization'] = "Bearer #{api_key}"
  req.body = {
    model: 'embedding-2',
    input: 'Samsung Galaxy S24 Ultra test'
  }.to_json
end

puts "Endpoint: /embeddings"
puts "Status: #{response.status}"
puts ''

if response.status == 200
  data = JSON.parse(response.body)
  puts "✅ SUCCESS!"
  puts "Model: #{data['model']}"
  puts "Embedding dimensions: #{data['data'].first['embedding'].length}"
  puts "Usage: #{data['usage']}"
else
  puts "❌ FAILED!"
  puts "Response: #{response.body[0..800]}"
end
