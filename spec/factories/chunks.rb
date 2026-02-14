# frozen_string_literal: true

FactoryBot.define do
  factory :chunk do
    association :chunkable, factory: :phone
    content { "Test chunk content" }
    chunk_index { 0 }
    metadata { {} }
  end
end
