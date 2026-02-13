# frozen_string_literal: true

module Api
  module V1
    class SemanticSearchController < ApplicationController
      include ErrorHandler
      skip_before_action :verify_authenticity_token

      # POST /api/v1/semantic_search
      # Search phones by natural language query using semantic similarity
      def create
        raise ArgumentError, 'Query parameter is required' if params[:query].blank?

        results = SemanticSearchService.search_phones(
          params[:query],
          country_id: params[:country_id],
          limit: params[:limit]&.to_i || 10,
          threshold: params[:threshold]&.to_f || 0.3
        )

        # Return in format expected by frontend: { data: [...] }
        render json: {
          data: results.map { |p| phone_serializer(p) },
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

      def phone_serializer(result)
        # Handle both Phone objects and Hash results from search service
        if result.is_a?(Hash)
          {
            id: result[:id],
            brand: result[:brand],
            model: result[:model],
            full_name: result[:full_name],
            url: result[:url],
            display_size: result[:display_size],
            storage: result[:storage],
            similarity: result[:similarity],
            content: result[:content]
          }
        else
          # Phone object
          {
            id: result.id,
            brand: result.brand,
            model: result.model,
            full_name: result.full_name,
            url: result.url,
            display_size: result.display_size,
            storage: result.storage,
            similarity: 0.85,
            specs: {
              display_type: result.display_type,
              storage: result.storage,
              ram: result.ram,
              camera: result.camera_specs
            }
          }
        end
      end
    end
  end
end
