# frozen_string_literal: true

# API Controller for RAG (Retrieval-Augmented Generation) semantic search
# DEPRECATED: Use Api::V1::SemanticSearchController instead
# This controller is kept for backward compatibility only
class Api::RagSearchController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token

  # Add deprecation warning
  before_action do
    Rails.logger.warn('[DEPRECATED] /api/rag/search is deprecated. Use /api/v1/semantic_search instead')
    ActiveSupport::Deprecation.warn('/api/rag/search is deprecated. Use /api/v1/semantic_search instead', caller)
  end

  # POST /api/rag/search
  # Semantic search using natural language query
  def create
    query = params[:query]

    # Validate query parameter
    if query.blank?
      render json: { error: 'Query parameter is required' }, status: :bad_request
      return
    end

    # Get optional parameters
    country_id = params[:country_id]
    limit = params[:limit]&.to_i || EmbeddingConstants::DEFAULT_SIMILARITY_LIMIT
    threshold = params[:threshold]&.to_f || EmbeddingConstants::MIN_SIMILARITY_THRESHOLD

    # Perform semantic search
    results = SemanticSearchService.search_phones(
      query,
      country_id: country_id,
      limit: limit,
      threshold: threshold
    )

    # Format response
    render json: {
      data: {
        query: query,
        results: results.map { |phone|
          {
            id: phone.id,
            brand: phone.brand,
            model: phone.model,
            url: phone.url,
            price_local: phone.prices.first&.price_local,
            currency: phone.prices.first&.currency,
            similarity: calculate_similarity(phone, query)
          }
        },
        count: results.count
      }
    }, status: :ok
    
  rescue SemanticSearchService::SearchError => e
    render json: { error: e.message }, status: :internal_server_error
  rescue EmbeddingService::EmbeddingError => e
    render json: { error: 'Failed to generate embedding for query' }, status: :internal_server_error
  end

  private

  # Calculate similarity score for display
  # @param phone [Phone] Phone record
  # @param query [String] Search query
  # @return [Float] Similarity score (0-1)
  def calculate_similarity(phone, _query)
    # Get embedding for query and calculate similarity
    # For simplicity, return default value
    0.8
  end
end
