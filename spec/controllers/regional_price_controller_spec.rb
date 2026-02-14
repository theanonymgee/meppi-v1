# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegionalPriceController, type: :controller do
  describe 'GET #index' do
    context 'with no country filter' do
      it 'returns regional comparison data' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:regional_data)).to be_present
      end
    end

    context 'with country filter' do
      let!(:country1) { create(:country, name: 'United Arab Emirates') }
      let!(:country2) { create(:country, name: 'Saudi Arabia') }

      it 'filters by selected countries' do
        get :index, params: { country_ids: [country1.id, country2.id] }

        expect(response).to have_http_status(:ok)
        expect(assigns(:regional_data)).to be_present
      end
    end
  end

  describe 'error handling' do
    it 'handles StandardError with alert' do
      allow(RegionalPriceService).to receive(:compare_to_base).and_raise(StandardError, 'Database error')

      get :index

      expect(response).to redirect_to(regional_price_list_path)
      expect(flash[:alert]).to be_present
    end
  end
end
