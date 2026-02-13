# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompetitionController, type: :controller do
  describe 'GET #index' do
    context 'with no country filter' do
      it 'returns market analysis data' do
        get :index, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['market_share']).to be_a(Hash)
        expect(json['top_models']).to be_a(Array)
        expect(json['new_entries']).to be_a(Array)
      end
    end

    context 'with country filter' do
      it 'filters by country' do
        country = create(:country, name: 'United Arab Emirates')
        get :index, params: { country_id: country.id }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid country' do
      it 'returns error for invalid country' do
        get :index, params: { country_id: 99999 }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['market_share']).to be_nil
      end
    end
  end

  describe 'GET #compare' do
    context 'with no phone_ids' do
      it 'renders comparison page' do
        get :compare

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:compare)
      end
    end

    context 'with valid phone_ids' do
      let(:phones) { create_list(:phone, 3) }

      it 'renders comparison data' do
        phone_ids = phones.map(&:id).join(',')

        get :compare, params: { phone_ids: phone_ids }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:compare)
        expect(assigns(:comparison_data)).to be_present
        expect(assigns(:insights)).to be_present
      end
    end

    context 'with invalid phone_ids' do
      it 'returns error for too few phones' do
        phone = create(:phone)
        get :compare, params: { phone_ids: phone.id.to_s }

        expect(response).to have_http_status(:ok)
        expect(assigns(:comparison_data)).to be_nil
      end
    end

    context 'with too many phone_ids' do
      it 'returns error for too many phones' do
        phones = create_list(:phone, 5)
        phone_ids = phones.map(&:id).join(',')

        get :compare, params: { phone_ids: phone_ids }

        expect(response).to have_http_status(:ok)
        expect(assigns(:comparison_data)).to be_nil
      end
    end
  end

  describe 'error handling' do
    it 'handles StandardError with alert' do
      allow(CompetitionService).to receive(:market_analysis).and_raise(StandardError, 'Database error')

      get :index

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
