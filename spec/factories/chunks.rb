# frozen_string_literal: true

FactoryBot.define do
  factory :chunk do
    association :phone
    content { "Test chunk content" }
    tokens { 100 }
  end
end
