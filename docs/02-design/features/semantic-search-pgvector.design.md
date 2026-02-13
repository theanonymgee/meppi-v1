# Design: Semantic Search with PostgreSQL pgvector

**Feature**: semantic-search-pgvector
**Created**: 2026-02-11
**Phase**: Design
**Status**: Ready for Implementation

## System Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Rails Application                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  API Layer                                               │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │  SemanticSearchController                         │  │   │
│  │  │  POST /api/v1/semantic_search                     │  │   │
│  │  └──────────────┬─────────────────────────────────────┘  │   │
│  └─────────────────┼──────────────────────────────────────────┘   │
│                    │                                             │
│  ┌─────────────────▼──────────────────────────────────────────┐   │
│  │  Service Layer                                            │   │
│  │  ┌─────────────────────────────────────────────────────┐  │   │
│  │  │  SemanticSearchService                             │  │   │
│  │  │  • search_phones(query, country_id, limit)         │  │   │
│  │  │  • find_similar(phone_id, limit)                   │  │   │
│  │  │  • _cosine_similarity(phone_embedding, query_emb)  │  │   │
│  │  └──────────────┬──────────────────────────────────────┘  │   │
│  └─────────────────┼──────────────────────────────────────────┘   │
│                    │                                             │
│  ┌─────────────────▼──────────────────────────────────────────┐   │
│  │  Client Layer                                             │   │
│  │  ┌─────────────────────────────────────────────────────┐  │   │
│  │  │  BgeM3Client                                        │  │   │
│  │  │  • generate(text) → Array<Float>                   │  │   │
│  │  │  • health_check → Boolean                          │  │   │
│  │  └──────────────┬──────────────────────────────────────┘  │   │
│  └─────────────────┼──────────────────────────────────────────┘   │
└────────────────────┼─────────────────────────────────────────────┘
                     │ HTTP
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│              BGE-M3 Flask Server (Port 8001)                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  /health (GET) → {status, model, dimensions}            │   │
│  │  /embeddings (POST) → {embedding, dimensions, model}    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Model: BAAI/bge-m3                                              │
│  Dimensions: 1024                                                │
└─────────────────────────────────────────────────────────────────┘

                     ┌──────────────────────────────────────┐
                     │   PostgreSQL + pgvector             │
                     │                                      │
                     │  ┌────────────────────────────────┐  │
                     │  │  phones                        │  │
                     │  │  • id SERIAL PK               │  │
                     │  │  • brand VARCHAR               │  │
                     │  │  • model VARCHAR               │  │
                     │  │  • embedding vector(1024)      │  │
                     │  │  • INDEX (embedding ivfflat)   │  │
                     │  └────────────────────────────────┘  │
                     │                                      │
                     │  ┌────────────────────────────────┐  │
                     │  │  prices                       │  │
                     │  │  • id SERIAL PK               │  │
                     │  │  • phone_id FK                │  │
                     │  │  • channel_id FK              │  │
                     │  │  • price_usd DECIMAL           │  │
                     │  │  • embedding vector(1024)      │  │
                     │  └────────────────────────────────┘  │
                     └──────────────────────────────────────┘
```

## Data Model

### PostgreSQL Schema

```sql
-- phones table (already exists)
CREATE TABLE phones (
  id SERIAL PRIMARY KEY,
  brand VARCHAR NOT NULL,
  model VARCHAR NOT NULL,
  url VARCHAR,
  display_type VARCHAR,
  storage VARCHAR,
  ram VARCHAR,
  camera_specs VARCHAR,
  embedding vector(1024),  -- pgvector column
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Index for cosine similarity
CREATE INDEX index_phones_on_embedding
ON phones
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- prices table (already exists)
CREATE TABLE prices (
  id SERIAL PRIMARY KEY,
  phone_id INTEGER REFERENCES phones(id),
  channel_id INTEGER REFERENCES channels(id),
  price_local DECIMAL,
  price_usd DECIMAL,
  date DATE,
  embedding vector(1024),  -- pgvector column
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Component Design

### 1. Migration Service

**File**: `lib/scripts/migrate_chromadb_to_pgvector.py`

**Responsibilities**:
- ChromaDB에서 임베딩 추출
- CSV 파일로 내보내기
- PostgreSQL 호환 형식 변환

**Interface**:
```python
def export_chromadb_to_csv(
    chromadb_path: str,
    output_csv: str,
    collection_name: str = "phones"
) -> dict:
    """Export ChromaDB embeddings to CSV

    Args:
        chromadb_path: Path to ChromaDB persist directory
        output_csv: Output CSV file path
        collection_name: ChromaDB collection name

    Returns:
        dict with stats: {exported_count, errors}
    """
```

**Output Format**:
```csv
phone_id,brand,model,embedding
1379,Apple,"Apple Watch 38mm (1st gen)",[-0.0034,-0.0047,...]
1380,Apple,"Apple Watch 42mm (1st gen)",[-0.0028,-0.0051,...]
```

---

### 2. Rake Task

**File**: `lib/tasks/embeddings.rake`

**Responsibilities**:
- CSV 파일 읽기
- PostgreSQL embedding 컬럼 업데이트
- 진행 상황 로깅

**Interface**:
```ruby
namespace :embeddings do
  desc "Import embeddings from CSV file"
  task import_from_csv: [:environment] do
    # Import logic
  end

  desc "Migrate ChromaDB to PostgreSQL"
  task migrate_chromadb: [:environment] do
    # Run Python export script
    # Import resulting CSV
  end
end
```

---

### 3. SemanticSearchService

**File**: `app/services/semantic_search_service.rb`

**Responsibilities**:
- 자연어 쿼리를 임베딩으로 변환
- pgvector 코사인 유사도 검색
- 국가 필터링
- 결과 캐싱

**Public Interface**:
```ruby
class SemanticSearchService
  # 자연어 검색
  def self.search_phones(
    query:,
    country_id: nil,
    limit: 10,
    threshold: 0.7
  ) => Array<Phone>

  # 유사 상품 찾기
  def self.find_similar(
    phone_id:,
    limit: 5,
    threshold: 0.7
  ) => Array<Phone>
end
```

**Implementation Details**:
```ruby
class SemanticSearchService
  class SearchError < StandardError; end

  # pgvector 코사인 거리 연산자: <=>
  # 거리가 0에 가까울수록 유사함
  # 코사인 유사도 = 1 - 거리

  def self.search_phones(query:, country_id: nil, limit: 10, threshold: 0.7)
    # 1. 쿼리 임베딩 생성
    query_embedding = EmbeddingService.generate(query)

    # 2. pgvector 코사인 유사도 검색
    # 거리 임계값: 1 - threshold
    distance_threshold = 1 - threshold

    results = Phone.where(
      "embedding <=> ? < ?",
      query_embedding,
      distance_threshold
    ).order(
      "embedding <=> #{query_embedding}"
    ).limit(limit)

    # 3. 국가 필터링 (선택사항)
    if country_id.present?
      phone_ids = Price.joins(:channel)
                       .where(channels: { country_id: country_id })
                       .pluck(:phone_id)

      results = results.where(id: phone_ids)
    end

    results.to_a
  rescue BgeM3Client::Error => e
    Rails.logger.error "Embedding generation failed: #{e.message}"
    raise SearchError, "Search service unavailable"
  end

  def self.find_similar(phone_id:, limit: 5, threshold: 0.7)
    phone = Phone.find(phone_id)

    return [] unless phone.embedding.present?

    distance_threshold = 1 - threshold

    Phone.where("embedding <=> ? < ?", phone.embedding, distance_threshold)
        .where.not(id: phone_id)
        .order("embedding <=> #{phone.embedding}")
        .limit(limit)
        .to_a
  end
end
```

---

### 4. SemanticSearchController

**File**: `app/controllers/api/v1/semantic_search_controller.rb`

**Responsibilities**:
- HTTP 요청 처리
- 파라미터 검증
- JSON 응답

**Interface**:
```ruby
class Api::V1::SemanticSearchController < ApplicationController
  include ErrorHandler

  # POST /api/v1/semantic_search
  def create
    results = SemanticSearchService.search_phones(
      query: params[:query],
      country_id: params[:country_id],
      limit: params[:limit] || 10,
      threshold: params[:threshold] || 0.7
    )

    render json: {
      results: results.map { |p| PhoneSerializer.as_json(p) },
      query: params[:query],
      total_found: results.length
    }
  end

  # GET /api/v1/semantic_search/:id/similar
  def similar
    results = SemanticSearchService.find_similar(
      phone_id: params[:id],
      limit: params[:limit] || 5
    )

    render json: {
      phone_id: params[:id],
      similar_phones: results.map { |p| PhoneSerializer.as_json(p) },
      total_found: results.length
    }
  end
end
```

---

### 5. PhoneSerializer

**File**: `app/serializers/phone_serializer.rb`

**Responsibilities**:
- Phone 모델을 JSON으로 변환
- 일관된 API 응답 형식

**Interface**:
```ruby
class PhoneSerializer
  def self.as_json(phone)
    {
      id: phone.id,
      brand: phone.brand,
      model: phone.model,
      full_name: phone.full_name,
      url: phone.url,
      specs: {
        display_type: phone.display_type,
        storage: phone.storage,
        ram: phone.ram,
        camera: phone.camera_specs
      }
    }
  end
end
```

## Error Handling

### Error Hierarchy

```
StandardError
└── SemanticSearchService::SearchError
    ├── EmbeddingService::EmbeddingError
    └── BgeM3Client::Error
```

### Error Responses

| Status | Scenario | Response |
|--------|----------|----------|
| 400 | Missing query | `{"error": "Query parameter is required"}` |
| 404 | Phone not found | `{"error": "Phone not found"}` |
| 503 | BGE-M3 server down | `{"error": "Search service unavailable"}` |
| 500 | Internal error | `{"error": "Internal server error"}` |

## Performance Optimization

### Database Indexing

```sql
-- IVFFlat index (already exists)
CREATE INDEX index_phones_on_embedding
ON phones USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- For 3,245 records, lists = sqrt(N) ≈ 57
-- Using lists = 100 for margin
```

### Caching Strategy

```ruby
# Rails.cache with 1-hour expiration
def self.search_phones(query:, ...)
  cache_key = "semantic_search/#{query}/#{country_id}/#{limit}"

  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    # ... search logic
  end
end
```

### Performance Targets

| Metric | Target |
|--------|--------|
| Embedding generation | < 100ms |
| Semantic search query | < 200ms |
| API response (total) | < 500ms |

## Testing Strategy

### Unit Tests

**File**: `test/services/semantic_search_service_test.rb`

```ruby
class SemanticSearchServiceTest < ActiveSupport::TestCase
  setup do
    @phone1 = Phone.create!(
      brand: "Samsung",
      model: "Galaxy S24 Ultra",
      embedding: test_embedding_vector
    )
  end

  test "search_phones returns relevant phones" do
    skip "Requires BGE-M3 server" unless server_running?

    results = SemanticSearchService.search_phones(query: "Samsung flagship")

    assert_includes results.map(&:id), @phone1.id
    assert_operator results.length, :<=, 10
  end

  test "search_phones filters by country" do
    # Test country filtering
  end

  test "find_similar returns similar phones" do
    results = SemanticSearchService.find_similar(phone_id: @phone1.id)

    assert results.all? { |p| p.id != @phone1.id }
  end
end
```

### Integration Tests

**File**: `test/controllers/api/v1/semantic_search_controller_test.rb`

```ruby
class Api::V1::SemanticSearchControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/v1/semantic_search returns results" do
    skip "Requires embeddings" unless Phone.where.not(embedding: nil).exists?

    post api_v1_semantic_search_url, params: {
      query: "Samsung Galaxy",
      limit: 5
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['results'].is_a?(Array)
    assert_operator json['total_found'], :<=, 5
  end

  test "POST returns 400 without query" do
    post api_v1_semantic_search_url, as: :json

    assert_response :bad_request
  end
end
```

## Deployment Checklist

- [ ] BGE-M3 server running on port 8001
- [ ] pgvector extension enabled
- [ ] Embedding columns exist (phones, prices)
- [ ] IVFFlat indexes created
- [ ] ChromaDB export script tested
- [ ] CSV import successful (3,245 records)
- [ ] SemanticSearchService tests passing
- [ ] API endpoint responding < 500ms
- [ ] Documentation updated

## Rollback Plan

If migration fails:
1. Stop BGE-M3 server
2. Drop embedding columns: `ALTER TABLE phones DROP COLUMN embedding`
3. Restore from backup: `pg_dump --clean --format=directory`

---

**Next Step**: `/pdca do semantic-search-pgvector`
