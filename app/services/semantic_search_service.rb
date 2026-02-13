# frozen_string_literal: true

# Service for semantic search using pgvector cosine similarity
# Supports natural language search on chunks (price data)
class SemanticSearchService
  class SearchError < StandardError; end

  # Search chunks by semantic similarity using natural language query
  # @param query [String] Natural language search query
  # @param country_id [Integer, nil] Optional country filter
  # @param limit [Integer] Maximum number of results
  # @param threshold [Float] Minimum similarity threshold 0-1 (default: 0.3 for broader results)
  # @return [Array<Hash>] Similar chunks with phone info ordered by relevance
  def self.search_phones(query, country_id: nil, limit: 10, threshold: 0.3)
    raise SearchError, "Query cannot be empty" if query.blank?

    # 1. Generate embedding for query using BgeM3Client
    client = BgeM3Client.new
    query_embedding = client.generate(query)

    # 2. Calculate distance threshold (cosine distance = 1 - cosine similarity)
    distance_threshold = 1 - threshold

    # 3. pgvector cosine similarity search on chunks
    embedding_str = "[#{query_embedding.map { |v| v.to_f }.join(',')}]"

    # Search chunks with embeddings and get similarity scores
    # Note: chunks uses polymorphic associations (chunkable_type, chunkable_id)
    sql = <<~SQL.squish
      SELECT
        c.id as chunk_id,
        c.content,
        c.chunkable_type,
        c.chunkable_id,
        1 - (c.embedding <=> '#{embedding_str}'::vector) as similarity
      FROM chunks c
      WHERE c.embedding IS NOT NULL
        AND (c.embedding <=> '#{embedding_str}'::vector) < #{distance_threshold}
      ORDER BY c.embedding <=> '#{embedding_str}'::vector
      LIMIT #{limit.to_i}
    SQL

    results = ActiveRecord::Base.connection.execute(sql).map do |row|
      {
        id: row['chunkable_id'] || row['chunk_id'],
        chunk_id: row['chunk_id'],
        brand: extract_brand(row['content']),
        model: nil,
        full_name: extract_phone_name(row['content']),
        content: row['content'],
        display_size: nil,
        storage: nil,
        similarity: row['similarity']&.round(4) || 0.5
      }
    end

    results
  rescue BgeM3Client::Error => e
    Rails.logger.error "Semantic search failed: #{e.message}"
    raise SearchError, 'Failed to perform semantic search'
  end

  # Extract phone name from chunk content
  def self.extract_phone_name(content)
    # Content format: "Samsung Galaxy S25 FE - du - 2999 AED (manual)"
    content.split(' - ').first&.strip || content[0..50]
  end

  # Extract brand from chunk content
  def self.extract_brand(content)
    phone_name = extract_phone_name(content)
    # Common brands
    brands = ['Samsung', 'Apple', 'iPhone', 'Xiaomi', 'OPPO', 'vivo', 'OnePlus', 'Google', 'Huawei', 'Realme']
    brands.find { |b| phone_name&.include?(b) } || phone_name&.split&.first || 'Unknown'
  end

  # Find similar phones based on embedding similarity
  # @param phone_id [Integer] ID of the reference phone
  # @param limit [Integer] Maximum number of similar phones
  # @return [Array<Phone>] Similar phones ordered by similarity
  def self.find_similar(phone_id, limit: 5, threshold: 0.7)
    phone = Phone.find(phone_id)

    return [] if phone.try(:embedding).blank?

    # 코사인 거리 임계값 계산
    distance_threshold = 1 - threshold

    # 코사인 거리로 유사한 폰 검색 (자신 제외)
    # embedding은 PostgreSQL vector 타입으로 저장되어 있으므로 문자열 그대로 사용
    embedding_str = phone.embedding.to_s
    Phone.where("embedding <=> ?::vector < ?", embedding_str, distance_threshold)
        .where.not(id: phone_id)
        .order(Arel.sql("embedding <=> '#{embedding_str}'::vector"))
        .limit(limit)
        .to_a
  end

  # Calculate similarity score between two phones
  # @param phone1 [Phone] First phone
  # @param phone2 [Phone] Second phone
  # @return [Float, nil] Similarity score (0-1), nil if embeddings missing
  def self.similarity_score(phone1, phone2)
    return nil if phone1.try(:embedding).blank? || phone2.try(:embedding).blank?

    # pgvector 코사인 거리를 사용하여 유사도 계산
    # 거리 = 1 - 코사인 유사도
    distance = ActiveRecord::Base.connection.select_value(
      'SELECT ? <=> ? AS distance',
      phone1.embedding,
      phone2.embedding
    )

    # 거리를 유사도로 변환 (cosine similarity = 1 - distance)
    1 - distance.to_f
  rescue StandardError => e
    Rails.logger.error "Similarity calculation failed: #{e.message}"
    nil
  end

  # Batch similarity search for multiple phones
  # @param phone_ids [Array<Integer>] IDs of phones to find similarities for
  # @param limit [Integer] Results per phone
  # @return [Hash<Integer, Array<Phone>> Map of phone_id to similar phones
  def self.batch_find_similar(phone_ids, limit: 5)
    result = {}

    phone_ids.each do |phone_id|
      begin
        result[phone_id] = find_similar(phone_id, limit: limit)
      rescue SearchError => e
        Rails.logger.error "Failed to find similar for phone #{phone_id}: #{e.message}"
        result[phone_id] = []
      end
    end

    result
  end
end
