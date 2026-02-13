#!/usr/bin/env ruby
# frozen_string_literal: true

# Chat completions 테스트
require 'json'

puts '=== Z.AI Chat Completions API 테스트 (JWT 인증) ==='
puts "Base URL: #{ENV['ZAI_API_BASE_URL']}"
puts "Model: #{ENV['ZAI_LLM_MODEL']}"
puts ''

begin
  client = ZAiClient.new(ENV.fetch('ZAI_API_KEY'))

  puts 'JWT 토큰 생성 완료!'
  puts ''

  puts 'Chat completions 요청 시도...'
  response = client.create_chat_completion(
    model: 'glm-4.7',
    messages: [
      { role: 'user', content: 'Hello, please say hi!' }
    ]
  )

  puts '✅ SUCCESS!'
  puts ''
  puts 'Response:'
  puts JSON.pretty_generate(response)

rescue ZAiClient::Error => e
  puts "❌ ZAiClient Error: #{e.message}"
  puts "Response body: #{e.message}"
rescue StandardError => e
  puts "❌ Error: #{e.class.name} - #{e.message}"
  puts e.backtrace.first(5)
end
