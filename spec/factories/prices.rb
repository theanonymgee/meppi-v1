FactoryBot.define do
  factory :price do
    phone_id { 1 }
    channel { nil }
    price_local { "9.99" }
    price_usd { "9.99" }
    price_type { "MyString" }
    stock_status { "MyString" }
    url { "MyText" }
    date { "2026-02-10" }
    scraped_at { "2026-02-10 23:09:11" }
  end
end
