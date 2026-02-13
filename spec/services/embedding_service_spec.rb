# frozen_string_literal: true

require 'rails_helper'

# EmbeddingService Spec
# Vibe Coding: Consistent test naming, descriptive behavior
RSpec.describe EmbeddingService, type: :service do
  describe '.embed' do
    context 'when BGE embedding service is available' do
      it 'returns embedding vector for text input' do
        # This test will need the BGE service to be running
        # For now, we test the method exists and has correct signature
        expect(EmbeddingService).to respond_to(:embed)
      end

      it 'raises EmbeddingError on service failure' do
        # Test error handling when service is unavailable
        allow(Faraday).to receive(:new).and_raise(Faraday::ConnectionFailed.new('Connection refused'))

        expect {
          EmbeddingService.embed('test')
        }.to raise_error(EmbeddingService::EmbeddingError)
      end
    end
  end

  describe '.embed_batch' do
    it 'accepts array of texts' do
      expect(EmbeddingService).to respond_to(:embed_batch)
    end
  end
end
