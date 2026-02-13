# frozen_string_literal: true

# Chunk model for storing text chunks with pgvector embeddings
# Used for semantic search on phone descriptions, channel descriptions, etc.
class Chunk < ApplicationRecord
  belongs_to :phone

  validates :content, presence: true

  # Enable pgvector for semantic search (RAG)
  # has_neighbors :embedding  # Uncomment when pgvector gem is properly configured

  # Scopes
  scope :by_phone, ->(phone_id) { where(phone_id:) }
  scope :recent, -> { order(created_at: :desc) }

  # Find similar chunks using pgvector cosine similarity
  # @param embedding [Array<Float>] Query embedding vector
  # @param limit [Integer] Maximum number of results
  # @param threshold [Float] Minimum similarity score (0-1)
  # @return [ActiveRecord::Relation] Similar chunks ordered by similarity
  def self.similar(embedding:, limit: 10, threshold: 0.7)
    # Use raw SQL for similarity search using pgvector <=> operator
    # Cosine similarity: 1 - (embedding <=> query_embedding)
    where('1 - (embedding <=> ?) >= ?', embedding, threshold)
      .limit(limit)
      .order('1 - (embedding <=> ?) DESC', embedding)
  end
end
