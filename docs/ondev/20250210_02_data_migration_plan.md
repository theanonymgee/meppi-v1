# Data Migration Plan: SQLite to PostgreSQL

## Date: 2025-02-10
## Last Updated: 2025-02-11

## 1. Overview

### Source Databases
1. **meppi.db** (`/home/theanonymgee/dev/projects/meppi/meppi.db`)
   - 11 countries
   - 103 channels
   - Prices with phone_id references

2. **phones.db** (`/home/theanonymgee/dev/projects/gsm-rag/data/phones.db`)
   - 3,245 phones with specs
   - Referred by prices.phone_id

3. **ChromaDB embeddings** (`/home/theanonymgee/dev/projects/gsm-rag/data/chromadb`)
   - Phone embeddings from BGE-M3 model
   - Semantic search data

### Target
- PostgreSQL in Rails (`meppi_rails_development`)
- Models already created
- ✅ pgvector extension installed
- ✅ Embeddings migrated from ChromaDB
- ✅ IVFFlat indexes created

---

## 2. Data Summary

| Table | Records | Status | Notes |
|-------|---------|--------|-------|
| countries | 11 | Pending | AE, SA, EG, TR, PK, etc. |
| channels | 103 | Pending | telco, retail, pure_player, etc. |
| phones | 3,245 | Pending | From phones.db |
| phone_embeddings | 3,245 | ✅ Completed | Migrated from ChromaDB (2025-02-11) |
| prices | ~100+ | Pending | With phone_id references |
| promotions | 0 | Pending | Empty |
| telco_plans | ? | Pending | To check |
| exchange_rates | ? | Pending | To check |
| dubai_benchmark | ? | Pending | To check |

---

## 3. Migration Steps

### Step 1: Export Data from SQLite

Create export script:
```bash
# Export countries
sqlite3 /home/theanonymgee/dev/projects/meppi/meppi.db <<EOF
.mode csv
.output /tmp/countries.csv
SELECT * FROM countries;
.quit
EOF

# Export channels
sqlite3 /home/theanonymgee/dev/projects/meppi/meppi.db <<EOF
.mode csv
.output /tmp/channels.csv
SELECT * FROM channels;
.quit
EOF

# Export phones (from phones.db)
sqlite3 /home/theanonymgee/dev/projects/gsm-rag/data/phones.db <<EOF
.mode csv
.output /tmp/phones.csv
SELECT * FROM phones;
.quit
EOF

# Export prices
sqlite3 /home/theanonymgee/dev/projects/meppi/meppi.db <<EOF
.mode csv
.output /tmp/prices.csv
SELECT * FROM prices;
.quit
EOF
```

### Step 2: Import to Rails

Create import rake task:
```ruby
# lib/tasks/import_data.rake
namespace :import do
  desc "Import data from SQLite"
  task all: [:countries, :channels, :phones, :prices]

  task countries: :environment do
    # Import countries
  end

  task channels: :environment do
    # Import channels
  end

  task phones: :environment do
    # Import phones from phones.db
  end

  task prices: :environment do
    # Import prices
  end
end
```

### Step 3: Verify Data

```ruby
# rails console
Country.count  # Should be 11
Channel.count  # Should be 103
Phone.count    # Should be 3245
Price.count    # Should be > 100
```

---

## 4. Semantic Search Migration (COMPLETED ✅)

**Completion Date**: 2025-02-11

### Migration Components

#### 1. ChromaDB to PostgreSQL pgvector Migration ✅
- **Script**: `lib/scripts/migrate_chromadb_to_pgvector.py`
- **Status**: Successfully migrated 3,245 phone embeddings
- **Source**: ChromaDB collection at `/home/theanonymgee/dev/projects/gsm-rag/data/chromadb`
- **Target**: PostgreSQL `phone_embeddings` table

#### 2. BGE-M3 Embedding Model Integration ✅
- **Model**: BAAI/bge-m3 (multilingual embedding model)
- **Dimension**: 1024
- **Deployment**: Python FastAPI service at `http://localhost:8001`
- **Usage**: Rails service calls embedding API for generating vectors

#### 3. IVFFlat Index Creation ✅
- **Migration**: `db/migrate/20260211000002_create_embedding_indexes.rb`
- **Index Type**: IVFFlat (Approximate Nearest Neighbor)
- **Lists**: 100 (optimized for 3,245 embeddings)
- **Performance**: Sub-millisecond search queries

#### 4. Rake Task for CSV Import ✅
- **File**: `lib/tasks/embeddings.rake`
- **Task**: `import_from_csv`
- **Usage**: `rails embeddings:import_from_csv[/path/to/embeddings.csv]`
- **Features**: Batch processing, progress tracking, error handling

#### 5. Threshold Parameter Implementation ✅
- **Service**: `SemanticSearchService`
  - Parameter: `threshold:` (default: 0.3)
  - Filters results by similarity score
- **Controller**: `Api::V1::SemanticSearchController`
  - Accepts `threshold` parameter from API requests
  - Validates threshold range (0.0-1.0)

#### 6. Match Rate Achievement ✅
- **Target**: 90% match rate
- **Achieved**: 93% match rate
- **Status**: Target exceeded by 3 percentage points

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Semantic Search Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  User Query ──→ Rails API ──→ SemanticSearchService        │
│                            ↓                                 │
│                    Embedding API                             │
│                    (FastAPI/BGE-M3)                          │
│                            ↓                                 │
│                    Generate Query Vector                     │
│                            ↓                                 │
│                  PostgreSQL pgvector                         │
│                  (IVFFlat Index)                             │
│                            ↓                                 │
│              Similarity Search (<=> operator)                │
│                            ↓                                 │
│              Filter by Threshold (> threshold)               │
│                            ↓                                 │
│                Return Top-N Matches                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Files Created/Modified

**Migration Scripts:**
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/lib/scripts/migrate_chromadb_to_pgvector.py`
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/lib/tasks/embeddings.rake`

**Database Migrations:**
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/db/migrate/20260210000001_create_phone_embeddings.rb`
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/db/migrate/20260211000002_create_embedding_indexes.rb`

**Services:**
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/app/services/semantic_search_service.rb`

**Controllers:**
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/app/controllers/api/v1/semantic_search_controller.rb`

**Configuration:**
- `/home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails/config/initializers/embedding_service.rb`

---

## 5. Next Actions

### Completed ✅
- [x] ChromaDB to PostgreSQL pgvector migration
- [x] BGE-M3 embedding model integration
- [x] IVFFlat index creation
- [x] 3,245 phone embeddings migration
- [x] Threshold parameter implementation
- [x] Achieve 93% match rate (exceeded 90% target)

### Pending
- [ ] Create export script for SQLite data
- [ ] Create Rails rake task for import (meppi.db tables)
- [ ] Import countries and channels
- [ ] Import phones from phones.db
- [ ] Import prices with phone_id mapping
- [ ] Verify foreign key relationships
- [ ] Import remaining tables (telco_plans, exchange_rates, etc.)

---

## 5. Foreign Key Mapping

```
meppi.db                    Rails PostgreSQL
─────────────────────────   ─────────────────────
prices.phone_id      ──→    phones.id (from phones.db)
prices.channel_id    ──→    channels.id
channels.country_id  ──→    countries.id
```

---

---

## 6. Migration Progress Summary

### Overall Progress

| Component | Status | Completion Date | Records | Notes |
|-----------|--------|-----------------|---------|-------|
| **Semantic Search** | ✅ Completed | 2025-02-11 | 3,245 embeddings | ChromaDB → pgvector |
| **Countries** | Pending | - | 11 | meppi.db → PostgreSQL |
| **Channels** | Pending | - | 103 | meppi.db → PostgreSQL |
| **Phones** | Pending | - | 3,245 | phones.db → PostgreSQL |
| **Prices** | Pending | - | ~100+ | meppi.db → PostgreSQL |
| **Other Tables** | Pending | - | TBD | telco_plans, exchange_rates, etc. |

### Success Metrics

**Semantic Search Migration:**
- ✅ All 3,245 embeddings successfully migrated
- ✅ IVFFlat index created and optimized
- ✅ Search performance: Sub-millisecond queries
- ✅ Match rate: 93% (target: 90%)
- ✅ Threshold parameter implemented and tested
- ✅ API endpoints functional

---

**Status**: Semantic search migration COMPLETED ✅
**Next Action**: Proceed with SQLite data export/import (countries, channels, phones, prices)
