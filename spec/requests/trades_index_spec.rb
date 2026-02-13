# frozen_string_literal: true

# Trades Index Request Spec - Test trades#index endpoint
# Single Responsibility: Test GET /trades returns proper list

require 'rails_helper'

RSpec.describe 'GET /trades', type: :request do
  let(:country) { create(:country) }
  let(:channel) { create(:channel, country: country) }
  let(:phone) { create(:phone) }

  it 'returns a list of trades' do
    create(:meppi_trade, country: country, channel: channel, phone: phone, title: 'Trade 1')
    create(:meppi_trade, country: country, channel: channel, phone: phone, title: 'Trade 2')

    get '/trades', as: :json

    expect(response).to have_http_status(200)
    json_response = response.parsed_body
    expect(json_response['data']['trades']).to be_an(Array)
    expect(json_response['data']['trades'].count).to eq(2)
    expect(json_response['data']['count']).to eq(2)
  end
end
