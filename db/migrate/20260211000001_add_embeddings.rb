# frozen_string_literal: true

# Add embedding columns for semantic search with pgvector
class AddEmbeddings < ActiveRecord::Migration[7.1]
  def change
    # Enable pgvector extension
    enable_extension 'vector'

    # Add embedding columns to phones table (Z.AI embeddings: 1024 dimensions)
    add_column :phones, :embedding, :vector, limit: 1024
    add_column :prices, :embedding, :vector, limit: 1024

    # Note: ivfflat indexes will be created in a separate migration after we have embedding data
    # ivfflat indexes require training data (typically 1000+ rows per index)
  end
end
