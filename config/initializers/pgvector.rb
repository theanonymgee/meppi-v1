# frozen_string_literal: true

# Pgvector configuration
# Register vector type with ActiveRecord for proper schema handling
# Note: The vector columns are stored in PostgreSQL and accessed as strings

# For now, we'll access embedding columns as text and parse them when needed
# The pgvector gem handles the conversion automatically in queries
