# frozen_string_literal: true

# Trades Destroy Request Spec - Test DELETE /trades/:id
# Single Responsibility: Test trade deletion functionality

require 'rails_helper'

RSpec.describe 'DELETE /trades/:id', type: :request do
  let(:country) { create(:country) }
  let(:channel) { create(:channel, country: country) }
  let(:phone) { create(:phone) }
  let(:trade) { create(:meppi_trade, country: country, channel: channel, phone: phone) }

  it 'deletes an existing trade' do
    trade

    expect { delete "/trades/#{trade.id}", as: :json }.to change { MeppiTrade.count }.by(-1)

    expect(response).to have_http_status(200)
  end

  it 'returns 404 for non-existent trade' do
    delete "/trades/999999", as: :json

    expect(response).to have_http_status(404)
  end
end
