#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

# Load environment
ENV['ZAI_API_BASE_URL'] = 'https://api.z.ai/api/paas/v4'

base_url = ENV.fetch('ZAI_API_BASE_URL')
api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Embedding API 테스트 (수정된 Base URL) ==='
puts "Base URL: #{base_url}"
puts "API Key: #{api_key[0..20]}..."
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
    model: 'embedding-v2',
    input: 'Samsung Galaxy S24 Ultra test'
  }.to_json
end

puts "Endpoint: /embeddings"
puts "Status: #{response.status}"
puts "Response: #{response.body[0..500]}..."
puts ''

if response.status == 200
  data = JSON.parse(response.body)
  puts "✅ SUCCESS!"
  puts "Model: #{data['model']}"
  puts "Embedding dimensions: #{data['data'].first['embedding'].length}"
else
  puts "❌ FAILED!"
end
