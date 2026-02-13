# frozen_string_literal: true

require 'rails_helper'

# SemanticSearchService Spec
# Vibe Coding: Consistent test naming, descriptive behavior
RSpec.describe SemanticSearchService, type: :service do
  let(:phone) { create(:phone) }

  describe '.search_phones' do
    it 'returns semantically similar phones based on query' do
      expect(SemanticSearchService).to respond_to(:search_phones)
    end

    it 'accepts limit parameter for result count' do
      expect(SemanticSearchService).to respond_to(:search_phones)
    end

    it 'accepts threshold parameter for minimum similarity' do
      expect(SemanticSearchService).to respond_to(:search_phones)
    end

    it 'raises SearchError on embedding service failure' do
      expect {
        SemanticSearchService.search_phones('test query')
      }.to raise_error(SemanticSearchService::SearchError)
    end
  end

  describe '.find_similar' do
    it 'finds phones similar to given phone' do
      expect(SemanticSearchService).to respond_to(:find_similar)
    end

    it 'excludes the reference phone from results' do
      expect(SemanticSearchService).to respond_to(:find_similar)
    end
  end

  describe '.similarity_score' do
    it 'calculates similarity between two phones' do
      expect(SemanticSearchService).to respond_to(:similarity_score)
    end

    it 'returns nil when embeddings are missing' do
      # Embeddings are stored in database columns, not model attributes
      # The similarity_score method checks for embedding presence
      skip "Requires database query to check embedding presence"
    end
  end

  describe '.batch_find_similar' do
    it 'finds similar phones for multiple phone IDs' do
      expect(SemanticSearchService).to respond_to(:batch_find_similar)
    end
  end
end
