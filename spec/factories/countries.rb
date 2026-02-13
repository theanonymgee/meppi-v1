FactoryBot.define do
  factory :country do
    sequence(:code) { |n| "C#{n}" }
    sequence(:name) { |n| "Country #{n}" }
    currency { "USD" }
    exchange_source { "manual" }
    priority { 1 }
    active { true }
  end
end
