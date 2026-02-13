# frozen_string_literal: true

# Trades Show Request Spec - Test GET /trades/:id
# Single Responsibility: Test single trade retrieval

require 'rails_helper'

RSpec.describe 'GET /trades/:id', type: :request do
  let(:country) { create(:country) }
  let(:channel) { create(:channel, country: country) }
  let(:phone) { create(:phone) }
  let(:trade) { create(:meppi_trade, country: country, channel: channel, phone: phone) }

  it 'returns 404 for non-existent trade' do
    get '/trades/999999', as: :json

    expect(response).to have_http_status(404)
  end

  it 'returns trade data for existing id' do
    get "/trades/#{trade.id}", as: :json

    expect(response).to have_http_status(200)
    json_response = response.parsed_body
    expect(json_response['data']['title']).to eq(trade.title)
    expect(json_response['data']['id']).to eq(trade.id)
  end
end
