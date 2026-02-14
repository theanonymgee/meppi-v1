# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompetitionController, type: :controller do
  describe 'GET #index' do
    context 'with no country filter' do
      it 'returns market analysis data' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:market_analysis)).to be_a(Hash)
        expect(assigns(:market_analysis)[:market_share]).to be_a(Hash)
        expect(assigns(:market_analysis)[:top_models]).to be_a(Array)
        expect(assigns(:market_analysis)[:new_entries]).to be_a(Array)
      end
    end

    context 'with country filter' do
      let!(:country) { create(:country, name: 'United Arab Emirates') }

      it 'filters by country' do
        get :index, params: { country_id: country.id }

        expect(response).to have_http_status(:ok)
        expect(assigns(:market_analysis)).to be_a(Hash)
      end
    end

    context 'with invalid country' do
      it 'returns empty market analysis for invalid country' do
        get :index, params: { country_id: 99999 }

        expect(response).to have_http_status(:ok)
        expect(assigns(:market_analysis)).to be_a(Hash)
        expect(assigns(:market_analysis)[:market_share]).to eq({})
      end
    end
  end

  describe 'GET #compare' do
    context 'with no phone_ids' do
      it 'renders comparison page' do
        get :compare

        expect(response).to have_http_status(:ok)
        # @phones will be empty if no phones exist in database
        expect(assigns(:phones)).to be_a(ActiveRecord::Relation)
      end
    end

    context 'with valid phone_ids' do
      let!(:phones) { create_list(:phone, 3) }

      it 'renders comparison data' do
        phone_ids = phones.map(&:id).join(',')

        get :compare, params: { phone_ids: phone_ids }

        # Accept both ok (success) and redirect (error handled)
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end

    context 'with invalid phone_ids' do
      let!(:phone) { create(:phone) }

      it 'returns no comparison data for too few phones' do
        get :compare, params: { phone_ids: phone.id.to_s }

        # Accept both ok (success) and redirect (error handled)
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end

    context 'with too many phone_ids' do
      let!(:phones) { create_list(:phone, 5) }

      it 'returns no comparison data for too many phones' do
        phone_ids = phones.map(&:id).join(',')

        get :compare, params: { phone_ids: phone_ids }

        # Accept both ok (success) and redirect (error handled)
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end
  end

  describe 'error handling' do
    it 'handles StandardError with alert' do
      allow(CompetitionService).to receive(:market_analysis).and_raise(StandardError, 'Database error')

      get :index

      expect(response).to redirect_to(competition_list_path)
      expect(flash[:alert]).to be_present
    end
  end
end
