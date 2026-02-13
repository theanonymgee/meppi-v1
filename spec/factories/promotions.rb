FactoryBot.define do
  factory :promotion do
    channel { nil }
    phone { nil }
    description { "MyText" }
    discount_percent { "9.99" }
    discount_amount_local { "9.99" }
    promo_code { "MyString" }
    valid_from { "2026-02-10" }
    valid_until { "2026-02-10" }
  end
end
