# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "NativeBridgeController" do
  describe "GET /api/v1/navigation" do
    it "returns navigation structure for native app" do
      get '/api/v1/navigation', as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['tabs']).to be_a(Array)
      expect(json['tabs'].length).to eq(4)

      # Verify structure - JSON.parse returns string keys
      expect(json['tabs'].first).to include('id')
      expect(json['tabs'].first).to include('label')
      expect(json['tabs'].first).to include('path')
    end

    it "includes correct tab IDs" do
      get '/api/v1/navigation', as: :json

      json = JSON.parse(response.body)
      tab_ids = json['tabs'].map { |t| t['id'] }

      expect(tab_ids).to include('channel')
      expect(tab_ids).to include('competition')
      expect(tab_ids).to include('promotion')
      expect(tab_ids).to include('regional')
    end

    it "includes correct tab labels" do
      get '/api/v1/navigation', as: :json

      json = JSON.parse(response.body)
      tab_labels = json['tabs'].map { |t| t['label'] }

      expect(tab_labels).to include('Channel Price')
      expect(tab_labels).to include('Competition')
      expect(tab_labels).to include('Promotion')
      expect(tab_labels).to include('Regional')
    end
  end
end
