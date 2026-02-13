#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'json'

api_key = ENV.fetch('ZAI_API_KEY')

puts '=== Z.AI Chat Completions API 테스트 (API Key 유효성 확인) ==='
puts ''

# Chat completions 테스트
base_url = 'https://open.bigmodel.cn/api/paas/v4'
endpoint = '/api/chat/completions'

conn = Faraday.new(base_url) do |f|
  f.request :json
  f.adapter Faraday.default_adapter
  f.options.timeout = 30
end

begin
  response = conn.post(endpoint) do |req|
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Bearer #{api_key}"
    req.body = {
      model: 'glm-4.7',
      messages: [
        { role: 'user', content: 'Hello' }
      ]
    }.to_json
  end

  puts "URL: #{base_url}#{endpoint}"
  puts "Status: #{response.status}"
  puts ''

  if response.status == 200
    data = JSON.parse(response.body)
    puts '✅ Chat Completions SUCCESS!'
    puts JSON.pretty_generate(data)
  else
    puts "❌ Chat Completions Failed"
    puts "Response: #{response.body[0..500]}"
  end
rescue StandardError => e
  puts "❌ Error: #{e.class.name} - #{e.message}"
end
