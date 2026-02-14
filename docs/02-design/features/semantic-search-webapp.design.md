# semantic-search-webapp Design Document

**Date:** 2026-02-13
**Feature:** semantic-search-webapp
**Phase:** Design

---

## Architecture

```
+--------------------------------------------------------------------------+
|                    semantic-search-webapp                                 |
+--------------------------------------------------------------------------+
|                                                                          |
|  +-------------------------------------------------------------+         |
|  |              Rails 7.1 Backend                              |         |
|  |  +-----------+-----------+-----------+----------+           |         |
|  |  | Embedding | Semantic  | Dashboard | API      |           |         |
|  |  | Service   | Search    | Controller| Routes   |           |         |
|  |  +-----------+-----------+-----------+----------+           |         |
|  +-------------------------------------------------------------+         |
|                                                                          |
|  +-------------------------------------------------------------+         |
|  |         BGE-M3 Embedding Server (Port 8002)                 |         |
|  |  - /api/v1/embed (single)                                   |         |
|  |  - /api/v1/embed/batch (batch)                              |         |
|  |  - 1024 dimensions                                          |         |
|  +-------------------------------------------------------------+         |
|                                                                          |
|  +-------------------------------------------------------------+         |
|  |         PostgreSQL + pgvector                               |         |
|  |  - chunks (embedding vector(1024))                          |         |
|  |  - cosine similarity search                                 |         |
|  +-------------------------------------------------------------+         |
+--------------------------------------------------------------------------+
```

---

## Component Design

### 1. BgeM3Client (Modified)

**File:** `app/services/bge_m3_client.rb`

```ruby
class BgeM3Client
  BASE_URL = ENV.fetch('BGE_M3_SERVER_URL', 'http://127.0.0.1:8002')
  EMBEDDING_DIM = 1024

  def generate(text)
    # POST /api/v1/embed
    # Response: { success: true, data: { embedding: [...] } }
  end

  def generate_batch(texts)
    # POST /api/v1/embed/batch
    # Response: { success: true, data: { embeddings: [[...], [...]] } }
  end
end
```

### 2. SemanticSearchService

**File:** `app/services/semantic_search_service.rb`

```ruby
class SemanticSearchService
  def initialize(query, options = {})
    @query = query
    @limit = options[:limit] || 10
    @threshold = options[:threshold] || 0.7
  end

  def search
    # 1. Generate embedding for query
    # 2. Find similar chunks using pgvector
    # 3. Return results with similarity scores
  end
end
```

### 3. API Endpoints

| Method | Endpoint | Controller#Action | Purpose |
|--------|----------|-------------------|---------|
| POST | /api/v1/semantic_search | api/v1/semantic_search#create | Semantic search |
| GET | /api/v1/navigation | api/v1/native_bridge#navigation | Native tabs |
| GET | /health | application#health | Health check |

### 4. Dashboard Views

**Structure:**
```
app/views/
├── layouts/
│   └── application.html.erb      # Editorial theme
├── dashboard/
│   └── index.html.erb            # 4 feature tabs
├── channel_comparison/
│   └── index.html.erb
├── competition/
│   └── index.html.erb
├── promotion/
│   └── index.html.erb
└── regional_price/
    └── index.html.erb
```

---

## Database Schema

### chunks table
```sql
CREATE TABLE chunks (
  id BIGSERIAL PRIMARY KEY,
  phone_id BIGINT NOT NULL REFERENCES phones(id),
  content TEXT NOT NULL,
  embedding VECTOR(1024),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_chunks_embedding ON chunks USING ivfflat (embedding vector_cosine_ops);
```

---

## Data Flow

```
User Query
    |
    v
+-------------------+
| API Controller    |
+-------------------+
    |
    v
+-------------------+
| SemanticSearch    |
| Service           |
+-------------------+
    |
    v
+-------------------+
| BgeM3Client       |
| (Port 8002)       |
+-------------------+
    |
    v
+-------------------+
| Query Embedding   |
+-------------------+
    |
    v
+-------------------+
| PostgreSQL        |
| pgvector search   |
+-------------------+
    |
    v
+-------------------+
| JSON Response     |
+-------------------+
```

---

## Testing Strategy

### Unit Tests
- BgeM3Client specs
- SemanticSearchService specs
- EmbeddingService specs

### Integration Tests
- API request specs
- Dashboard controller specs

### E2E Tests (Playwright)
- User search journey
- Dashboard navigation
- Error handling scenarios

---

## Configuration

### Environment Variables
```bash
BGE_M3_SERVER_URL=http://127.0.0.1:8002
BGE_M3_TIMEOUT=30
DATABASE_URL=postgresql://...
```

### pgvector Initializer
```ruby
# config/initializers/pgvector.rb
require 'pgvector'

ActiveRecord::Base.connection.enable_extension('vector')
```
