#!/usr/bin/env ruby
# frozen_string_literal: true

# API Key 직접 인증 방식 테스트
require 'json'

puts '=== Z.AI Embedding API 테스트 (API Key 직접 인증) ==='
puts "Base URL: #{ENV['ZAI_API_BASE_URL']}"
puts "Model: #{ENV['ZAI_EMBEDDING_MODEL']}"
puts ''

begin
  client = ZAiClient.new(ENV.fetch('ZAI_API_KEY'))

  puts 'API Key 직접 인증으로 임베딩 생성 시도...'
  response = client.create_embedding(
    model: 'embedding-2',
    input: 'Samsung Galaxy S24 Ultra test'
  )

  puts '✅ SUCCESS!'
  puts ''
  puts 'Response:'
  puts JSON.pretty_generate(response)
  puts ''
  puts "Model: #{response['model']}"
  puts "Object: #{response['object']}"
  puts "Embedding dimensions: #{response['data'].first['embedding'].length}"
  puts "Usage: #{response['usage']}"

rescue ZAiClient::Error => e
  puts "❌ ZAiClient Error: #{e.message}"
rescue StandardError => e
  puts "❌ Error: #{e.class.name} - #{e.message}"
  puts e.backtrace.first(5)
end
