# frozen_string_literal: true

# Create chunks table for storing text chunks with pgvector embeddings
# Used for semantic search on phone descriptions, channel descriptions, etc.
class CreateChunks < ActiveRecord::Migration[7.1]
  def change
    # Enable pgvector extension
    enable_extension 'vector'

    create_table :chunks do |t|
      t.references :chunkable, polymorphic: true, null: false, index: true
      t.text :content, null: false
      t.integer :chunk_index
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # Add embedding column using raw SQL
    execute 'ALTER TABLE chunks ADD COLUMN embedding vector(1024)'

    add_index :chunks, [:chunkable_type, :chunkable_id, :chunk_index],
              unique: true,
              name: 'index_chunks_on_chunkable_and_index'
    add_index :chunks, :metadata, using: :gin
  end
end
