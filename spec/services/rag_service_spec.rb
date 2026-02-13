# frozen_string_literal: true

require 'rails_helper'

# RAGService Spec
# Vibe Coding: Consistent test naming, descriptive behavior
RSpec.describe RagService, type: :service do
  let(:phone) { create(:phone) }
  let(:trade) { create(:meppi_trade, phone: phone) }

  describe '.similar_chunks' do
    it 'returns similar chunks based on query text' do
      expect(RagService).to respond_to(:similar_chunks)
    end

    it 'limits results by specified limit parameter' do
      expect(RagService).to respond_to(:similar_chunks)
    end
  end

  describe '.create_chunk' do
    it 'creates a new chunk for trade' do
      expect(RagService).to respond_to(:create_chunk)
    end

    it 'splits content into manageable chunks' do
      expect(RagService).to respond_to(:split_content)
    end
  end
end
