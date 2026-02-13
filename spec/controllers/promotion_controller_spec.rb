# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromotionController, type: :controller do
  describe 'GET #index' do
    context 'with no filters' do
      it 'returns promotion data' do
        get :index, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['discount_rankings']).to be_a(Array)
        expect(json['active_count']).to be_a(Numeric)
      end
    end

    context 'with country filter' do
      let(:country) { create(:country, name: 'United Arab Emirates') }

      it 'filters by country' do
        get :index, params: { country_id: country.id }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with brand filter' do
      let(:phone) { create(:phone, brand: 'Samsung') }

      it 'filters by brand' do
        get :index, params: { brand_id: phone.brand }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'error handling' do
    it 'handles StandardError with alert' do
      allow(PromotionService).to receive(:active_promotions).and_raise(StandardError, 'Database error')

      get :index

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
