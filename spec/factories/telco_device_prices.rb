FactoryBot.define do
  factory :telco_device_price do
    price { nil }
    plan { nil }
    device_price_local { "9.99" }
    monthly_installment { "9.99" }
    total_cost_24m_local { "9.99" }
    effective_device_price { "9.99" }
    notes { "MyText" }
  end
end
