# frozen_string_literal: true

require 'rails_helper'

# Chunk Model Spec
# Vibe Coding: Consistent test naming, descriptive behavior
RSpec.describe Chunk, type: :model do
  let(:phone) { create(:phone) }
  let(:chunk) { create(:chunk, phone: phone, content: 'Test content', tokens: 100) }

  describe 'associations' do
    it 'belongs to a phone' do
      expect(chunk.phone).to eq(phone)
    end
  end

  describe 'validations' do
    it 'requires content' do
      invalid_chunk = build(:chunk, content: nil)
      expect(invalid_chunk).not_to be_valid
      expect(invalid_chunk.errors[:content]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    before { chunk }

    it 'returns chunks by phone' do
      expect(Chunk.by_phone(phone.id)).to include(chunk)
    end

    it 'returns recent chunks first' do
      expect(Chunk.recent.first).to eq(chunk)
    end
  end
end
