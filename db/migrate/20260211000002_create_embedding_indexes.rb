class CreateEmbeddingIndexes < ActiveRecord::Migration[7.1]
  def change
    # IVFFlat index requires at least 1000 rows
    # phones table has 3245 rows, so we can create IVFFlat index

    # For lists parameter: sqrt(total_rows) is a good starting point
    # sqrt(3245) ≈ 57, using 100 for better precision

    # Note: embeddings are stored as text, need to cast to vector for index
    # The index creation will handle this automatically with pgvector

    enable_extension "vector" unless extension_enabled?("vector")

    # IVFFlat index for phones.embedding
    # Using cosine similarity operator class
    add_index :phones, :embedding,
              using: :ivfflat,
              opclass: :vector_cosine_ops,
              name: "index_phones_on_embedding_ivfflat",
              comment: "IVFFlat index for cosine similarity search on phones"

    # Create same index for prices if prices have embeddings
    # Check if prices table has embeddings
    if Price.column_names.include?("embedding")
      add_index :prices, :embedding,
                using: :ivfflat,
                opclass: :vector_cosine_ops,
                name: "index_prices_on_embedding_ivfflat",
                comment: "IVFFlat index for cosine similarity search on prices"
    end
  end
end
