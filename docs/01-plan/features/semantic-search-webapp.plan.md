# semantic-search-webapp Plan Document

**Date:** 2026-02-13
**Feature:** semantic-search-webapp
**Phase:** Plan

---

## Goal

Build a complete semantic search web application with:
1. Vector embedding generation using BGE-M3 (port 8002)
2. Semantic search functionality for 2,941 chunks
3. Web UI with Rails + Hotwire Native
4. E2E verification with Playwright

---

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Generate embeddings for all 2,941 chunks using BGE-M3 | High |
| FR-02 | Semantic search with cosine similarity >= 0.7 | High |
| FR-03 | Dashboard with 4 feature tabs (Channel, Competition, Promotion, Regional) | High |
| FR-04 | API endpoint for semantic search POST /api/v1/semantic_search | High |
| FR-05 | Health check endpoint | Medium |
| FR-06 | Error handling with user-friendly messages | Medium |

### Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Embedding generation time | < 1 second per chunk |
| NFR-02 | Search response time | < 500ms |
| NFR-03 | Test coverage | >= 85% |
| NFR-04 | GAP match rate | >= 90% |

---

## Technical Stack

- **Backend:** Ruby on Rails 7.1
- **Database:** PostgreSQL + pgvector
- **Embedding:** BGE-M3 (1024 dimensions) on port 8002
- **Frontend:** Hotwire (Turbo + Stimulus), TailwindCSS
- **Testing:** RSpec, Playwright

---

## Implementation Phases

### Phase 1: Embedding Infrastructure
1. Fix BgeM3Client to use port 8002 and `/api/v1/embed` endpoint
2. Configure pgvector properly
3. Generate embeddings for all 2,941 chunks
4. Verify embedding quality

### Phase 2: Semantic Search Service
1. Implement SemanticSearchService with cosine similarity
2. Create API endpoint POST /api/v1/semantic_search
3. Add validation and error handling
4. Write service specs

### Phase 3: Web Dashboard
1. Create DashboardController with 4 feature tabs
2. Build views with Turbo Frames
3. Add Stimulus controllers for interactivity
4. Style with Tailwind editorial theme

### Phase 4: E2E Testing
1. Set up Playwright
2. Create user journey scenarios
3. Test edge cases
4. Verify GAP >= 90%

---

## Success Criteria

- [ ] All 2,941 chunks have embeddings
- [ ] Semantic search returns relevant results (similarity >= 0.7)
- [ ] Dashboard loads successfully with all tabs
- [ ] All tests passing
- [ ] GAP match rate >= 90%
- [ ] Playwright E2E tests passing
