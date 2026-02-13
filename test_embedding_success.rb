#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

api_key = ENV.fetch('ZAI_API_KEY')
base_url = 'https://api.z.ai/api/paas/v4'
endpoint = '/api/embeddings'

puts '=== Z.AI Embedding API 성공한 엔드포인트 테스트 ==='
puts "URL: #{base_url}#{endpoint}"
puts ''

conn = Faraday.new(base_url) do |f|
  f.request :json
  f.adapter Faraday.default_adapter
  f.options.timeout = 30
end

response = conn.post(endpoint) do |req|
  req.headers['Content-Type'] = 'application/json'
  req.headers['Authorization'] = "Bearer #{api_key}"
  req.body = {
    model: 'embedding-2',
    input: 'Samsung Galaxy S24 Ultra test'
  }.to_json
end

puts "Status: #{response.status}"
puts "Headers: #{response.headers}"
puts ''
puts "Raw Response Body:"
puts response.body
puts ''

if response.status == 200
  begin
    data = JSON.parse(response.body)
    puts "✅ JSON Parse 성공!"
    puts "Response Keys: #{data.keys}"
    puts "Full Response:"
    puts JSON.pretty_generate(data)
  rescue JSON::ParserError => e
    puts "❌ JSON Parse 실패: #{e.message}"
  end
end
