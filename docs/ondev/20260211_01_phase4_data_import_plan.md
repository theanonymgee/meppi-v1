# Phase 4: Data Import Pipeline

**Created**: 2026-02-11
**Status**: 🔄 In Progress
**Match Rate**: TBD
**Last Updated**: 2026-02-12

---

## 1. Overview

### Purpose
MEPPY 시스템의 기존 SQLite 데이터를 PostgreSQL로 마이그레이션하고, 시맨틱 검색을 위한 임베딩을 생성합니다.

### Scope
- 기존 SQLite 데이터베이스 읽기
- BGE-M3 임베딩 서버를 통한 텍스트 임베딩
- PostgreSQL 대량 데이터 import
- pgvector 인덱스 생성

### Dependencies
- Python 3.12+
- BGE-M3 model (사전 설치됨)
- sentence-transformers
- Flask
- Rails 7.1.0

---

## 2. Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                                                  │
│  Phase 3: Dashboard UI                          │
│  (Rails 7.1, PostgreSQL, Tailwind)           │
│                                                  │
└─────────────────────────────────────────────────────────┘
                         ↓↓↓↓↓↓↓
┌─────────────────────────────────────────────────────────┐
│                                                  │
│  Phase 4: Data Import Pipeline                    │
│  ┌──────────────────────────────────────────────┐   │
│  │ 1. SQLite Reader                   │   │
│  │    - Read phones, prices              │   │
│  │    - Export to CSV                   │   │
│  └──────────────────────────────────────────┘   │
│                         ↓↓↓↓↓↓              │
│  ┌──────────────────────────────────────────────┐   │
│  │ 2. BGE-M3 Embedding Service         │   │
│  │    - HTTP API                      │   │
│  │    - Generate 1024-dim vectors        │   │
│  │    - Batch processing                │   │
│  └──────────────────────────────────────────┘   │
│                         ↓↓↓↓↓↓              │
│  ┌──────────────────────────────────────────────┐   │
│  │ 3. PostgreSQL Import Service        │   │
│  │    - Bulk insert                    │   │
│  │    - Pgvector indexing              │   │
│  │    - Transaction management          │   │
│  └──────────────────────────────────────────┘   │
│                         ↓↓↓↓↓↓              │
│  ┌──────────────────────────────────────────────┐   │
│  │ 4. Rails Update                    │   │
│  │    - Background jobs                 │   │
│  │    - Progress tracking              │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

```
[SQLite Database] → [Export CSV] → [BGE-M3 Embeddings] → [PostgreSQL Import] → [Rails Dashboard]
                    ↓                              ↓                  ↓
(Phones, Prices)      (Text → Vector)              (Phones + Embeddings)       (Display)
```

### Database Schema Analysis

**Source SQLite Tables** (12 tables):
1. `countries` (12 records) - Country master data
2. `channels` (110 records) - Sales channels per country
3. `prices` (2,288 records) - Pricing data with external phone_id reference
4. `telco_plans` (5 records) - Mobile carrier plans
5. `telco_device_prices` (28 records) - Device pricing with plans
6. `promotions` (0 records) - Promotional data
7. `exchange_rates` (12 records) - Currency exchange rates
8. `dubai_benchmark` (14 records) - Dubai pricing benchmarks
9. `effective_prices` - Calculated effective pricing view
10. `cheapest_prices_per_phone` - Aggregate view
11. `most_expensive_prices_per_phone` - Aggregate view
12. `country_price_comparison` - Comparison view

**Key Finding**: No `phones` table in SQLite
- Phone data must come from external source (likely gsm-rag)
- Prices table references `phone_id` that points to external system
- Need separate phone import pipeline before importing prices

**Destination PostgreSQL Tables** (migrated):
- Countries ✅ (12 records)
- Channels ✅ (118 records including existing)
- Telco Plans ✅ (5 records)
- Telco Device Prices ✅ (28 records)
- Dubai Benchmarks ✅ (14 records)
- Exchange Rates ✅ (12 records)
- Phones ❌ (awaiting external data source)
- Prices ❌ (blocked by missing phones)

---

## 3. Implementation Plan

### Step 1: SQLite Data Extraction

**Location**: `lib/tasks/sqlite_reader.rb`

**Input**: SQLite databases (`/path/to/meppi.db`)

**Output**: CSV files
- `phones_export.csv`
- `prices_export.csv`
- `channels_export.csv`
- `countries_export.csv`

**Tasks**:
1. SQLite 데이터베이스 연결
2. 테이블 schema 확인 (phones, prices, channels, countries)
3. CSV export
4. 데이터 검증

**Acceptance Criteria**:
- All rows exported without errors
- CSV file size > 0
- Sample data validates correctly

---

### Step 2: BGE-M3 Embedding Generation

**Location**: `lib/tasks/bge_m3_batch_embedder.rb`

**Input**: CSV files from Step 1

**Output**: CSV files with embeddings
- `phones_with_embeddings.csv`
- `prices_meta.csv`

**Tasks**:
1. CSV 파일 읽기
2. BGE-M3 서버 연결 확인 (http://127.0.0.1:8001/health)
3. 텍스트 필드 생성 (brand + model + specs)
4. 배치 임베딩 요청 (/embeddings/batch)
5. 응답 저장

**Acceptance Criteria**:
- All embeddings generated (1024-dim vectors)
- No API errors (>50% success rate)
- Output CSV valid

**BGE-M3 API**:
```ruby
# Endpoints
POST /embeddings/batch
{
  "texts": ["text1", "text2", ...],
  "response": {
    "embeddings": [[float...]],  # Array of 1024-dim vectors
    "count": 2
  }
}
```

---

### Step 3: PostgreSQL Import

**Location**: `lib/tasks/postgresql_importer.rb`

**Input**: CSV files from Step 2

**Output**: Database tables populated

**Tasks**:
1. PostgreSQL 연결
2. Foreign key constraint 확인
3. Bulk insert (phones + embeddings)
4. Pgvector 인덱스 생성
5. 통계 업데이트

**Acceptance Criteria**:
- All records inserted without errors
- Embedding columns populated
- Indexes created successfully
- Record count matches source

**SQL Operations**:
```sql
-- Bulk insert with embeddings
INSERT INTO phones (brand, model, display_type, storage, ram, camera_specs, embedding)
VALUES ($1, $2, $3, $4, $5, $6, $7::vector)
ON CONFLICT (brand, model) DO NOTHING
RETURNING id;

-- Create pgvector index
CREATE INDEX ON phones USING hnsw (embedding vector_cosine_ops);
```

---

### Step 4: Rails Integration

**Location**: Rails services, controllers

**Tasks**:
1. Import task service 생성
2. Background job framework
3. Progress tracking API
4. Dashboard에 진행상태 표시

**API Endpoints**:
```ruby
POST /api/v1/tasks/import_data
  - Trigger data import
  - Returns: { task_id: "...", status: "running" }

GET /api/v1/tasks/:id
  - Returns: { task_id: "...", status: "...", progress: 45% }
```

---

## 4. Testing Strategy

### Unit Tests
- `spec/tasks/sqlite_reader_spec.rb`
- `spec/tasks/bge_m3_batch_embedder_spec.rb`
- `spec/tasks/postgresql_importer_spec.rb`

### Integration Tests
- `spec/tasks/data_import_pipeline_spec.rb`

**Test Cases**:
1. SQLite export produces valid CSV
2. BGE-M3 server handles batch requests
3. PostgreSQL import handles duplicate records
4. Rails API correctly tracks progress

---

## 5. Vibe Coding Compliance

### ✅ Consistent Pattern
- 모든 import 태스크는 동일한 구조 사용
- `lib/tasks/` 디렉토리
- 각 태스크는 `call` 메서드로 진입점 제공

### ✅ One Source of Truth
- 데이터베이스 연결은 `DatabaseConnection` 클래스로 관리
- 모든 상수는 `lib/constants/`에 정의

### ✅ No Hardcoding
- 테이블 이름, 파일 경로는 상수로 정의
- BGE-M3 API URL은 환경변수

### ✅ Error & Exception Handling
- 모든 태스크는 `begin/rescue` 블록 사용
- SQLite 연결, API 요청 실패 시 적절한 에러 처리

### ✅ Single Responsibility
- 각 태스크는 하나의 책임만 담당
- SQLite Reader, BGE-M3 Embedder, PostgreSQL Importer

### ✅ Shared Code Management
- `lib/tasks/base_task.rb`에 공통 로직 추출
- 각 태스크는 `BaseTask` 상속

---

## 6. Progress Update (2026-02-12)

### Completed
- ✅ `lib/tasks/` 디렉토리 생성
- ✅ `lib/tasks/base_task.rb` 생성 (abstract base class)
- ✅ SQLite database 확인 and copied to project
- ✅ Step 1: SQLite Reader 구현 완료
  - ✅ 12 tables exported successfully (2,702 total records)
  - ✅ CSV files generated in `tmp/exports/`
  - ✅ Test script created: `scripts/test_sqlite_reader.rb`
- ✅ Step 3: PostgreSQL Importer 구현 완료
  - ✅ Countries, Channels, Telco Plans imported
  - ✅ Test script created: `scripts/test_postgresql_importer.rb`
  - ✅ 47 new records imported

### Issues Found
1. **Missing phones table**: SQLite database does not have a `phones` table
   - The prices table references `phone_id` from an external source (gsm-rag)
   - Phone data must be imported separately from the GSM database

2. **Data Import Order**:
   - Countries → Channels → Telco Plans → (External Phones) → Prices
   - Prices require phones to exist first (foreign key constraint)

### In Progress
- 🔄 Step 2: Phone data migration strategy (needs external source identification)
- 🔄 Step 4: BGE-M3 Batch Embedder (requires phone data)

---

## 7. Checklist

### Before Implementation
- [x] `lib/tasks/` 디렉토리 생성
- [x] `lib/tasks/base_task.rb` 생성
- [x] SQLite database 확인
- [ ] BGE-M3 서버 실행 중 확인
- [x] PostgreSQL pgvector 확장 확인

### Implementation Tasks
- [x] Step 1: SQLite Reader 구현
- [ ] Step 2: BGE-M3 Batch Embedder 구현 (blocked by phone data)
- [x] Step 3: PostgreSQL Importer 구현 (partial - pricing data only)
- [ ] Step 2.5: Phone data import from external source (NEW - required first)
- [ ] Step 4: Rails Integration 구현

### Testing Tasks
- [x] SQLite Reader test script created and tested
- [x] PostgreSQL Importer test script created and tested
- [ ] Unit tests 작성
- [ ] Integration tests 작성
- [ ] RSpec 실행: `bundle exec rspec`

### Deployment
- [x] Countries, Channels, Telco data imported
- [ ] Phone data import from external source
- [ ] Prices linked to imported phones
- [ ] 대시보드에서 데이터 확인
- [ ] Phase 5 준비

---

## 8. Implementation Notes

### Files Created/Modified

**Task Infrastructure**:
- `lib/tasks/base_task.rb` - Abstract base class for all import tasks
- `lib/tasks/sqlite_reader.rb` - SQLite to CSV exporter
- `lib/tasks/postgresql_importer.rb` - CSV to PostgreSQL importer

**Test Scripts**:
- `scripts/test_sqlite_reader.rb` - Test SQLite export
- `scripts/test_postgresql_importer.rb` - Test PostgreSQL import

### Commands to Run

```bash
# Export data from SQLite
RAILS_ENV=development ruby scripts/test_sqlite_reader.rb

# Import data to PostgreSQL
RAILS_ENV=development ruby scripts/test_postgresql_importer.rb

# View current database state
rails c
> Country.count
> Channel.count
> Price.count
```

---

## 9. Notes

### BGE-M3 Server Configuration
- **Port**: 8001 (default)
- **Host**: 127.0.0.1
- **Model**: `BAAI/bge-m3`
- **Health Check**: http://127.0.0.1:8001/health

### Data Volumes (SQLite)
- `meppi.db` - 원본 SQLite 데이터베이스
- `meppi_backup.db` - 백업본

### PostgreSQL Considerations
- 기존 `phones` 테이블에 `embedding` 컬럼 추가
- `bytea` 타입 사용 (1024-dim vectors)
- pgvector HNSW 인덱싱 (coarse to fine search)

---

*Last Updated: 2026-02-12*

**Session Summary**: Successfully implemented SQLite Reader and PostgreSQL Importer for pricing data. Phone data import requires external source identification (likely gsm-rag). 47 new records imported to PostgreSQL database.
