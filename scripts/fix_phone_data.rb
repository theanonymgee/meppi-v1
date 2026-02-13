# frozen_string_literal: true

# Fix phone data to match prices phone_ids
# Run with: rails runner scripts/fix_phone_data.rb

puts "=== Phone Data Fix Script ==="

# Step 1: Clear existing phones (IDs 1-18)
puts "Deleting existing phones..."
Phone.delete_all

# Step 2: Create phones with correct IDs matching prices data
phones_data = [
  # Samsung - using numeric IDs from prices table
  { id: 10, brand: "Samsung", model: "Galaxy S25 FE" },
  { id: 23, brand: "Samsung", model: "Galaxy S25 Edge" },
  { id: 38, brand: "Samsung", model: "Galaxy S25 Ultra" },
  { id: 39, brand: "Samsung", model: "Galaxy S25+" },
  { id: 40, brand: "Samsung", model: "Galaxy S25" },
  { id: 44, brand: "Samsung", model: "Galaxy S24 FE" },
  { id: 67, brand: "Samsung", model: "Galaxy S24 Ultra" },
  { id: 68, brand: "Samsung", model: "Galaxy S24+" },
  { id: 69, brand: "Samsung", model: "Galaxy S24" },
  # Apple - using numeric IDs from prices table
  { id: 1080, brand: "Apple", model: "iPhone 16e" },
  { id: 1082, brand: "Apple", model: "iPhone 16 Pro Max" },
  { id: 1083, brand: "Apple", model: "iPhone 16 Pro" },
  { id: 1084, brand: "Apple", model: "iPhone 16 Plus" },
  { id: 1085, brand: "Apple", model: "iPhone 16" },
  { id: 1091, brand: "Apple", model: "iPhone 15 Pro Max" },
  { id: 1092, brand: "Apple", model: "iPhone 15 Pro" },
  { id: 1093, brand: "Apple", model: "iPhone 15 Plus" },
  { id: 1094, brand: "Apple", model: "iPhone 15" }
]

puts "Inserting phones with correct IDs..."
phones_data.each do |data|
  phone = Phone.new(data)
  phone.save(validate: false)
  print "."
end
puts ""

puts "Created #{Phone.count} phones"
puts "Phone IDs: #{Phone.pluck(:id).sort.join(', ')}"
