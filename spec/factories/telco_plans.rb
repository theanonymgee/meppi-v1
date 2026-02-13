FactoryBot.define do
  factory :telco_plan do
    channel { nil }
    plan_name { "MyString" }
    monthly_fee_local { "9.99" }
    contract_months { 1 }
    data_gb { "MyString" }
    minutes { "MyString" }
    active { false }
  end
end
