# frozen_string_literal: true

FactoryBot.define do
  factory :channel do
    association :country
    sequence(:name) { |n| "Channel #{n}" }
    channel_type { "retail" }
    sequence(:url) { |n| "https://example.com/channel#{n}" }
    active { true }
  end
end
