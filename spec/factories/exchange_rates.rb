FactoryBot.define do
  factory :exchange_rate do
    country { nil }
    rate_official { "9.99" }
    rate_black_market { "9.99" }
    rate_used { "9.99" }
    date { "2026-02-10" }
    source { "MyString" }
  end
end
