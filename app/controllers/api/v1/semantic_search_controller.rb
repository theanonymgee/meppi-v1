# frozen_string_literal: true

module Api
  module V1
    class SemanticSearchController < ApplicationController
      include ErrorHandler

      # POST /api/v1/semantic_search
      # Search phones by natural language query using semantic similarity
      def create
        raise ArgumentError, 'Query parameter is required' if params[:query].blank?

        results = SemanticSearchService.search_phones(
          params[:query],
          country_id: params[:country_id],
          limit: params[:limit]&.to_i || EmbeddingConstants::DEFAULT_SIMILARITY_LIMIT,
          threshold: params[:threshold]&.to_f || EmbeddingConstants::MIN_SIMILARITY_THRESHOLD
        )

        render json: {
          results: results.map { |p| phone_serializer(p) },
          query: params[:query],
          total_found: results.length
        }
      end

      # GET /api/v1/semantic_search/:id/similar
      # Find similar phones by phone ID
      def similar
        phone = Phone.find(params[:id])

        results = SemanticSearchService.find_similar(
          phone.id,
          limit: params[:limit]&.to_i || 5,
          threshold: params[:threshold]&.to_f || EmbeddingConstants::MIN_SIMILARITY_THRESHOLD
        )

        render json: {
          phone: phone_serializer(phone),
          similar_phones: results.map { |p| phone_serializer(p) },
          total_found: results.length
        }
      end

      private

      def phone_serializer(phone)
        {
          id: phone.id,
          brand: phone.brand,
          model: phone.model,
          full_name: phone.full_name,
          url: phone.url,
          specs: {
            display_type: phone.display_type,
            storage: phone.storage,
            ram: phone.ram,
            camera: phone.camera_specs
          }
        }
      end
    end
  end
end
