# frozen_string_literal: true

# MeppiTrade Model Spec
# Single Responsibility: Test MeppiTrade model validations and associations

require 'rails_helper'

RSpec.describe MeppiTrade, type: :model do
  describe 'associations' do
    it 'belongs to phone' do
      expect(MeppiTrade.reflect_on_association(:phone).belongs_to?).to be true
    end

    it 'belongs to channel' do
      expect(MeppiTrade.reflect_on_association(:channel).belongs_to?).to be true
    end

    it 'belongs to country' do
      expect(MeppiTrade.reflect_on_association(:country).belongs_to?).to be true
    end
  end

  describe 'validations' do
    it 'requires title' do
      trade = MeppiTrade.new(title: '')
      expect(trade.valid?).to be false
      expect(trade.errors[:title]).to be_present
    end

    it 'requires price_local' do
      trade = MeppiTrade.new(price_local: nil)
      expect(trade.valid?).to be false
      expect(trade.errors[:price_local]).to be_present
    end

    it 'requires currency' do
      trade = MeppiTrade.new(currency: '')
      expect(trade.valid?).to be false
      expect(trade.errors[:currency]).to be_present
    end
  end

  describe '.compact' do
    it 'deletes trades older than 30 days' do
      # Create test trades
      old_trade = MeppiTrade.create!(title: 'Old Trade', price_local: 100, currency: 'USD', created_at: 35.days.ago)
      recent_trade = MeppiTrade.create!(title: 'Recent Trade', price_local: 200, currency: 'USD', created_at: 1.day.ago)

      initial_count = MeppiTrade.count

      # Run compact
      MeppiTrade.compact

      final_count = MeppiTrade.count

      expect(final_count).to eq(initial_count - 1)
      expect(MeppiTrade.find_by(id: old_trade.id)).to be_nil
      expect(MeppiTrade.find_by(id: recent_trade.id)).not_to be_nil
    end
  end
end
