# frozen_string_literal: true

# Pgvector configuration
# The pgvector gem is used for vector similarity search

# Note: We use raw SQL for vector operations since ActiveRecord integration
# can be tricky. The embedding column is stored as a vector type in PostgreSQL.
