# Plan: Semantic Search with PostgreSQL pgvector

**Feature**: semantic-search-pgvector
**Created**: 2026-02-11
**Phase**: Plan

## Overview

ChromaDB에 저장된 3,245개 폰 임베딩을 PostgreSQL pgvector로 마이그레이션하고, Rails 네이티브 시맨틱 검색 기능을 구현합니다.

## Background

### Current State
- **ChromaDB**: 3,245개 폰 임베딩 저장됨 (1024차원)
- **BGE-M3 Server**: Flask 서버 실행 중 (포트 8001)
- **PostgreSQL**: pgvector 설치됨, phones/prices 테이블에 embedding 컬럼 존재
- **Rails**: BgeM3Client 구현됨

### Problem Statement
1. ChromaDB와 PostgreSQL 이중 데이터베이스 관리 복잡
2. 데이터 동기화 필요 (임베딩 vs 메타데이터)
3. Rails에서 Python IPC 통해 ChromaDB 접근 (성능 저하)

## Objectives

### Primary Goals
1. ✅ **마이그레이션**: ChromaDB → PostgreSQL pgvector 임베딩 복사
2. ✅ **검색 서비스**: SemanticSearchService 구현
3. ✅ **API 엔드포인트**: POST /api/v1/semantic_search
4. ✅ **테스트**: 시맨틱 검색 기능 검증

### Success Criteria
- [ ] 3,245개 임베딩 PostgreSQL로 복사 완료
- [ ] "Samsung Galaxy" 검색 시 관련 폰 Top 10 반환
- [ ] 검색 응답 시간 500ms 이하
- [ ] 테스트 커버리지 80% 이상

## Technical Approach

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│  Rails Application                                      │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  SemanticSearchService                         │    │
│  │  • search_phones(query, country_id, limit)      │    │
│  │  • find_similar(phone_id, limit)               │    │
│  └──────────────┬──────────────────────────────────┘    │
│                 │                                        │
│                 ▼                                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  BgeM3Client                                   │    │
│  │  • generate(text) → embedding                  │    │
│  └──────────────┬──────────────────────────────────┘    │
│                 │                                        │
│                 ▼                                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  BGE-M3 Flask Server (Port 8001)               │    │
│  │  • /embeddings (POST)                          │    │
│  │  • /health (GET)                               │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  PostgreSQL + pgvector                         │    │
│  │  • phones (id, brand, model, embedding)        │    │
│  │  • prices (id, phone_id, embedding)            │    │
│  │  • Cosine similarity: embedding <=> query      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Implementation Strategy

#### Phase 1: Migration (ChromaDB → PostgreSQL)
1. Python 스크립트로 ChromaDB 임베딩 추출
2. CSV 파일로 내보내기
3. Rails Rake task로 PostgreSQL import

#### Phase 2: SemanticSearchService 구현
1. pgvector 코사인 유사도 검색
2. 국가 필터링 지원
3. 캐싱 (Rails.cache)

#### Phase 3: API 엔드포인트
1. SemanticSearchController
2. PhoneSerializer
3. Error handling

## Dependencies

### External Services
- **BGE-M3 Server**: `http://127.0.0.1:8001` (실행 중)
- **ChromaDB**: `/home/theanonymgee/dev/projects/gsm-rag/data/vectordb`

### Ruby Gems
- `faraday` (HTTP client)
- `pgvector` (ActiveRecord extension)

### Python Packages
- `chromadb`
- `numpy`

## Scope

### In Scope
- ✅ ChromaDB → PostgreSQL 임베딩 마이그레이션
- ✅ SemanticSearchService 구현
- ✅ POST /api/v1/semantic_search 엔드포인트
- ✅ 테스트 코드 작성

### Out of Scope
- ❌ 실시간 임베딩 자동 생성 (Phase 3)
- ❌ Turbo Streams UI (Phase 3)
- ❌ 대규모 데이터 최적화 (10만개 이상)

## Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Migration Script | 30분 |
| 2 | SemanticSearchService | 1시간 |
| 3 | API Controller | 30분 |
| 4 | Testing | 30분 |

**Total Estimated Time**: 2.5시간

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ChromaDB 접근 실패 | Low | High | Python 스크립트로 확인 |
| PostgreSQL 임베딩 타입 불일치 | Medium | High | migration 전 테스트 |
| BGE-M3 서버 다운 | Low | Medium | health check 추가 |
| 성능 저하 | Low | Low | 인덱스 최적화 |

## Deliverables

1. **Migration Script**: `lib/scripts/migrate_chromadb_to_pgvector.py`
2. **Rake Task**: `lib/tasks/embeddings.rake`
3. **Service**: `app/services/semantic_search_service.rb`
4. **Controller**: `app/controllers/api/v1/semantic_search_controller.rb`
5. **Tests**: `test/services/semantic_search_service_test.rb`
6. **API Docs**: `docs/api/semantic_search.md`

## Acceptance Criteria

- [ ] All 3,245 embeddings imported to PostgreSQL
- [ ] Semantic search returns relevant results
- [ ] API endpoint responds within 500ms
- [ ] Test coverage > 80%
- [ ] Code passes RuboCop checks
- [ ] Documentation updated

---

**Next Step**: `/pdca design semantic-search-pgvector`
