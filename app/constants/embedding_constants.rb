# frozen_string_literal: true

# Embedding-related constants for Z.AI integration
module EmbeddingConstants
  # BGE-M3 embedding model (local inference)
  EMBEDDING_MODEL = 'BAAI/bge-m3'.freeze
  EMBEDDING_DIMENSIONS = 1024  # BGE-M3 embedding dimensions

  # Similarity search settings
  DEFAULT_SIMILARITY_LIMIT = 10
  MIN_SIMILARITY_THRESHOLD = 0.7

  # Batch processing
  EMBEDDING_BATCH_SIZE = 100
end
