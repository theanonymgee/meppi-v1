# frozen_string_literal: true

# Service for semantic search using pgvector cosine similarity
# Supports natural language search and similar item discovery
class SemanticSearchService
  class SearchError < StandardError; end

  # Search phones by semantic similarity using natural language query
  # @param query [String] Natural language search query
  # @param country_id [Integer, nil] Optional country filter
  # @param limit [Integer] Maximum number of results
  # @param threshold [Float] Minimum similarity threshold 0-1 (default: 0.7)
  # @return [Array<Phone>] Similar phones ordered by relevance
  def self.search_phones(query, country_id: nil, limit: 10, threshold: 0.7)
    raise SearchError, "Query cannot be empty" if query.blank?

    # 1. 쿼리에서 임베딩 생성 (BGE-M3)
    query_embedding = EmbeddingService.embed(query)

    # 2. 유사도 기반 거리 임계값 계산 (cosine distance = 1 - cosine similarity)
    distance_threshold = 1 - threshold

    # 3. pgvector 코사인 유사도 검색 (Raw SQL 사용)
    embedding_str = "[#{query_embedding.join(',')}]"

    # 거리 임계값을 적용하여 필터링
    sql = <<~SQL.squish
      SELECT id FROM phones
      WHERE embedding IS NOT NULL
        AND embedding <=> '#{embedding_str}'::vector < #{distance_threshold}
      ORDER BY embedding <=> '#{embedding_str}'::vector
      LIMIT #{limit.to_i}
    SQL

    phone_ids = ActiveRecord::Base.connection.execute(sql).map { |row| row['id'] }

    # 4. Phone 객체 로드
    similar_phones = Phone.where(id: phone_ids).to_a

    # 5. 국가 필터링 (선택사항)
    if country_id.present?
      country_phone_ids = Price.joins(:channel)
                             .where(channels: { country_id: country_id })
                             .pluck(:phone_id)

      similar_phones = similar_phones.select { |p| country_phone_ids.include?(p.id) }
    end

    similar_phones
  rescue EmbeddingService::EmbeddingError => e
    Rails.logger.error "Semantic search failed: #{e.message}"
    raise SearchError, 'Failed to perform semantic search'
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
