#!/usr/bin/env ruby
#
# Test runner for BGE-M3 Batch Embedder
# Usage: ruby scripts/test_bge_embedder.rb
#

require_relative '../lib/tasks/bge_m3_batch_embedder'

# Create a test phone hash
test_phone = {
  id: 1,
  brand: 'Samsung',
  model: 'Galaxy S24',
  display_type: 'AMOLED',
  storage: '128GB',
  ram: '8GB',
  camera_specs: '108MP + 12MP + 5MP'
}

# Create embedder instance
embedder = BgeM3BatchEmbedder.new

# Test health check
puts "=" * 50
puts "1. Testing BGE-M3 Health Check..."
if embedder.check_api_health
  puts "   ✓ Health: OK"
else
  puts "   ✗ Health: FAILED"
  return
end

# Test single embedding
puts ""
puts "2. Testing Single Embedding..."
result = embedder.generate_embedding("Samsung Galaxy S24")
if result[:success]
  puts "   ✓ Embedding generated"
  puts "   Dimensions: #{result[:dimensions]}"
  puts "   Vector size: #{result[:embedding]&.length}"
else
  puts "   ✗ Failed: #{result[:error]}"
  return
end

# Test batch embedding
puts ""
puts "3. Testing Batch Embedding..."
test_texts = [
  'Apple iPhone 13',
  'Samsung Galaxy S24',
  'Xiaomi Redmi Note 12'
]

result = embedder.generate_batch(test_texts)

if result[:success]
  puts "   ✓ Batch completed"
  puts "   Generated #{result[:count]} embeddings"
  puts "   Dimensions: #{EMBEDDING_DIM}"
else
  puts "   ✗ Failed: #{result[:error]}"
  return
end

puts ""
puts "=" * 50
puts "Tests completed!"
