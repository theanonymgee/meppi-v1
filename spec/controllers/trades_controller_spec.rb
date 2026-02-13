# frozen_string_literal: true

require 'rails_helper'

# Trades Controller Spec - Test CRUD operations for MeppiTrade
# Vibe Coding: Consistent test naming, descriptive behavior, single responsibility
RSpec.describe TradesController, type: :controller do
  # Test setup - create required associations
  let(:country) { create(:country, code: 'US', name: 'United States', currency: 'USD') }
  let(:channel) { create(:channel, country: country) }
  let(:phone) { create(:phone) }
  let(:trade) { create(:meppi_trade, country: country, channel: channel, phone: phone) }

  describe 'GET #index' do
    context 'when fetching all trades' do
      before { trade }

      it 'returns a successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns trades with proper serialization' do
        get :index
        json_response = JSON.parse(response.body)
        expect(json_response['data']['trades']).to be_an(Array)
        expect(json_response['data']['trades'].first).to include('id', 'title', 'price_local')
      end
    end
  end

  describe 'GET #show' do
    context 'when trade exists' do
      it 'returns the trade details' do
        get :show, params: { id: trade.id }
        expect(response).to have_http_status(:success)
      end

      it 'returns serialized trade data' do
        get :show, params: { id: trade.id }
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to include('title' => trade.title)
      end
    end

    context 'when trade does not exist' do
      it 'raises not found error' do
        expect do
          get :show, params: { id: 999999 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          trade: {
            phone_id: phone.id,
            channel_id: channel.id,
            country_id: country.id,
            title: 'New Trade',
            brand: 'Samsung',
            price_local: 1000.0,
            price_usd: 270.0,
            currency: 'AED',
            stock_status: 'in_stock',
            url: 'https://example.com/trade',
            trade_type: 'retail',
            valid_until: 30.days.from_now.to_date,
            discount_percent: 10.0,
            discount_amount_local: 100.0,
            promo_code: 'SAVE10'
          }
        }
      end

      it 'creates a new trade' do
        expect do
          post :create, params: valid_params
        end.to change(MeppiTrade, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          trade: {
            title: '', # Invalid: empty title
            price_local: nil, # Invalid: missing price
            currency: '' # Invalid: empty currency
          }
        }
      end

      it 'does not create a new trade' do
        expect do
          post :create, params: invalid_params
        end.not_to change(MeppiTrade, :count)
      end

      it 'returns unprocessable content status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:update_params) do
        {
          id: trade.id,
          trade: {
            title: 'Updated Trade Title',
            price_local: 1200.0
          }
        }
      end

      it 'updates the trade' do
        patch :update, params: update_params
        trade.reload
        expect(trade.title).to eq('Updated Trade Title')
      end

      it 'returns ok status' do
        patch :update, params: update_params
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when trade exists' do
      it 'deletes the trade' do
        trade
        expect do
          delete :destroy, params: { id: trade.id }
        end.to change(MeppiTrade, :count).by(-1)
      end

      it 'returns ok status' do
        trade
        delete :destroy, params: { id: trade.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'private methods' do
    context 'serialize_trade' do
      it 'correctly serializes trade data' do
        serialized = controller.send(:serialize_trade, trade)
        expect(serialized).to include(
          id: trade.id,
          title: trade.title,
          price_local: trade.price_local.to_f
        )
      end
    end

    context 'trade_params' do
      it 'permits only allowed parameters' do
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            trade: {
              title: 'Test',
              brand: 'Samsung',
              price_local: 1000,
              currency: 'AED',
              stock_status: 'in_stock',
              url: 'https://example.com',
              trade_type: 'retail',
              valid_until: 30.days.from_now,
              discount_percent: 10,
              discount_amount_local: 100,
              promo_code: 'SAVE10'
            }
          )
        )

        permitted_params = controller.send(:trade_params)
        expect(permitted_params).to be_a(ActionController::Parameters)
      end
    end
  end
end
