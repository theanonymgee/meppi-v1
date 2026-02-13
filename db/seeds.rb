# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "🌱 Seeding database..."

# Countries
countries_data = [
  { code: 'AE', name: 'United Arab Emirates', currency: 'AED', priority: 1, active: true },
  { code: 'SA', name: 'Saudi Arabia', currency: 'SAR', priority: 2, active: true },
  { code: 'QA', name: 'Qatar', currency: 'QAR', priority: 3, active: true },
  { code: 'KW', name: 'Kuwait', currency: 'KWD', priority: 4, active: true },
  { code: 'BH', name: 'Bahrain', currency: 'BHD', priority: 5, active: true },
  { code: 'OM', name: 'Oman', currency: 'OMR', priority: 6, active: true }
]

countries_data.each do |country_data|
  Country.find_or_create_by!(code: country_data[:code]) do |country|
    country.name = country_data[:name]
    country.currency = country_data[:currency]
    country.priority = country_data[:priority]
    country.active = country_data[:active]
  end
end

puts "✅ Created #{Country.count} countries"

# Create some channels
uae = Country.find_by(code: 'AE')
sa = Country.find_by(code: 'SA')

channels = [
  { country: uae, name: 'Sharaf DG UAE', channel_type: 'retail', url: 'https://sharafdg.com/ae', active: true },
  { country: uae, name: 'Amazon UAE', channel_type: 'retail', url: 'https://amazon.ae', active: true },
  { country: sa, name: 'Amazon KSA', channel_type: 'retail', url: 'https://amazon.sa', active: true },
  { country: uae, name: 'Etisalat', channel_type: 'telco', url: 'https://etisalat.ae', active: true }
]

channels.each do |channel_data|
  Channel.find_or_create_by!(name: channel_data[:name], country_id: channel_data[:country].id) do |channel|
    channel.channel_type = channel_data[:channel_type]
    channel.url = channel_data[:url]
    channel.active = channel_data[:active]
  end
end

puts "✅ Created #{Channel.count} channels"

# Create some phones
phones_data = [
  { brand: 'Apple', model: 'iPhone 15 Pro', url: 'https://apple.com/iphone-15-pro' },
  { brand: 'Apple', model: 'iPhone 15', url: 'https://apple.com/iphone-15' },
  { brand: 'Samsung', model: 'Galaxy S24 Ultra', url: 'https://samsung.com/galaxy-s24-ultra' },
  { brand: 'Samsung', model: 'Galaxy S24', url: 'https://samsung.com/galaxy-s24' },
  { brand: 'Google', model: 'Pixel 8 Pro', url: 'https://store.google.com/pixel' }
]

phones_data.each do |phone_data|
  Phone.find_or_create_by!(brand: phone_data[:brand], model: phone_data[:model]) do |phone|
    phone.url = phone_data[:url]
  end
end

puts "✅ Created #{Phone.count} phones"

# Create some sample prices
if Price.count == 0
  Phone.find_each do |phone|
    Channel.active.each do |channel|
      # Random price between 2000 and 8000 AED
      price = 2000 + rand(6000)

      Price.create!(
        phone_id: phone.id,
        channel_id: channel.id,
        price_local: price,
        price_usd: price * 0.27, # Approximate USD rate
        price_type: 'nominal',
        stock_status: 'in_stock',
        date: Date.today,
        scraped_at: DateTime.now
      )
    end
  end
end

puts "✅ Created #{Price.count} prices"

# Create sample telco plans
if TelcoPlan.count == 0
  channels_with_type = Channel.where(channel_type: 'telco')

  channels_with_type.each do |channel|
    3.times do |i|
      TelcoPlan.create!(
        channel_id: channel.id,
        plan_name: "#{channel.name} Plan #{i + 1}",
        monthly_fee_local: 100 + (i * 50),
        contract_months: 24,
        data_gb: "#{(10 + i * 5)}GB",
        minutes: "Unlimited",
        active: true
      )
    end
  end
end

puts "✅ Created #{TelcoPlan.count} telco plans"

puts "🎉 Database seeded successfully!"