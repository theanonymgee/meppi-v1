# frozen_string_literal: true

# Trades Request Spec - Basic API functionality
# Single Responsibility: Test TradesController CRUD operations

require 'rails_helper'

RSpec.describe 'Trades API', type: :request do
  describe 'GET /trades' do
    it 'returns empty list when no trades exist' do
      get '/trades', as: :json

      expect(response.parsed_body).to eq({
        'data' => { 'trades' => [], 'count' => 0 }
      })
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /trades' do
    let(:country) { create(:country) }
    let(:channel) { create(:channel, country: country) }
    let(:phone) { create(:phone) }

    it 'creates a new trade with valid params' do
      trade_attrs = {
        phone_id: phone.id,
        channel_id: channel.id,
        country_id: country.id,
        title: 'Test Trade',
        brand: 'TestBrand',
        price_local: 100.50,
        price_usd: 27.36,
        currency: 'USD',
        stock_status: 'in_stock'
      }

      post '/trades', params: { trade: trade_attrs }, as: :json

      expect(response).to have_http_status(201)
      json_response = response.parsed_body
      expect(json_response['data']['title']).to eq('Test Trade')
      expect(json_response['data']['price_local']).to eq(100.5)
    end

    it 'returns error for missing title' do
      post '/trades', params: { trade: { price_local: 100 } }, as: :json

      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors']).to be_present
    end
  end
end
