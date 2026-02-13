# frozen_string_literal: true

FactoryBot.define do
  factory :phone do
    brand { "Samsung" }
    model { "Galaxy S24" }
    sequence(:url) { |n| "https://example.com/phone#{n}" }
    image_url { "https://example.com/images/phone.jpg" }
    announced { "2024-01" }
    released { "2024-02" }
    display_size { "6.7 inches" }
    display_type { "AMOLED" }
    chipset { "Snapdragon 8 Gen 3" }
    cpu { "Octa-core" }
    gpu { "Adreno 750" }
    ram { "8GB" }
    storage { "256GB" }
    main_camera { "50MP + 12MP + 10MP" }
    selfie_camera { "12MP" }
    battery { "5000mAh" }
    os { "Android 14" }
    price { "$999" }
    specs_json { '{"display": "6.7 inches"}' }
    scraped_at { Time.current }
  end
end
