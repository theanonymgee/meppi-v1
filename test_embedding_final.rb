#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

# Load environment with CORRECTED values
ENV['ZAI_API_BASE_URL'] = 'https://open.bigmodel.cn/api/paas/v4'

base_url = ENV.fetch('ZAI_API_BASE_URL')
api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Embedding API 테스트 (최종 수정본) ==='
puts "Base URL: #{base_url}"
puts "API Key: #{api_key[0..20]}..."
puts "Model: embedding-2"
puts ''

# Test /embeddings endpoint with correct settings
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
  puts "Object: #{data['object']}"
  puts "Embedding dimensions: #{data['data'].first['embedding'].length}"
  puts "Usage: #{data['usage']}"
else
  puts "❌ FAILED!"
  puts "Response: #{response.body}"
end
