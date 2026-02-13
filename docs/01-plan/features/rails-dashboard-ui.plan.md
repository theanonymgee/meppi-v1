# Plan: Rails Dashboard UI Implementation

**Feature**: rails-dashboard-ui
**Created**: 2026-02-11
**Phase**: Plan
**Design Direction**: Editorial (Financial Times style)

## Overview

Python Streamlit 대시보드를 Ruby on Rails 웹 인터페이스로 마이그레이션합니다. 경영진을 위한 데이터 시각화 대시보드로 5개 페이지 (Home, Channel Strategy, Competition, Promotions, Regional Prices)를 구현합니다.

## Background

### Current State
- **Phase 2 (Semantic Search)**: ✅ 완료 (Match Rate: 93%)
- **Backend**: Rails 7.1 API 모드 (api_only = true)
- **Database**: 3,245 Phones, 1,878 Prices, 103 Channels, 11 Countries
- **Embeddings**: BGE-M3 (1024차원), pgvector 인덱스 생성됨
- **API**: RESTful API 엔드포인트 구현됨

### Problem Statement
1. **기존 Streamlit**: Python 기반, 별도 프로세스로 실행 필요
2. **단일 플랫폼**: Rails API + Streamlit (유지보수 복잡)
3. **사용자 경험**: 경영진을 위한 전문적인 대시보드 UI 부재
4. **실시간 업데이트**: Hotwire를 활용한 동적 업데이트 미구현

### Migration Target
- **Source**: `/home/theanonymgee/dev/tools/meppi/dashboard/` (Python Streamlit)
- **Target**: Rails Hotwire + Tailwind CSS (Single Rails App)
- **Pages**: 5개 페이지 (Home, Channel Strategy, Competition, Promotions, Regional Prices)

## Objectives

### Primary Goals
1. **Rails Web Interface**: API-only 모드 → Web 모드 전환
2. **5개 페이지 구현**: 각 페이지별 데이터 시각화 및 상호작용
3. **Editorial Design**: Financial Times 스타일의 세련된 UI
4. **Hotwire Integration**: Turbo + Stimulus로 실시간 업데이트
5. **Chart.js 연동**: 반응형 차트 라이브러리 통합

### Success Criteria
- [ ] API-only 모드 해제 및 Web views 활성화
- [ ] 5개 페이지 모두 접근 가능 (GET /dashboard/:page)
- [ ] 각 페이지별 KPI 카드 및 차트 렌더링
- [ ] Semantic Search UI 통합 (자연어 검색)
- [ ] 반응형 디자인 (모바일/태블릿/데스크톱)
- [ ] 페이지 로드 시간 < 2초
- [ ] Editorial 디자인 일관성 (Serif 폰트, 여백, 색상)

## Design Direction: Editorial (Financial Times Style)

### Typography
- **Display Font**: `Playfair Display` (Serif)
  - 헤딩 h1-h3, 페이지 타이틀
  - 권위 있고 신문적인 느낌
- **Body Font**: `Source Sans Pro` (Sans-serif)
  - 본문 텍스트, UI 요소
  - 가독성 및 현대적인 느낌
- **Monospace Font**: `IBM Plex Mono`
  - 데이터 테이블, 가격 정보
  - 기술적인 정밀함 표현

### Color Palette
```css
/* Muted, sophisticated palette */
--color-bg-primary: #FDFBF7;      /* Warm off-white (newsprint) */
--color-bg-secondary: #F5F2EA;    /* Slightly darker */
--color-text-primary: #1A1A1A;    /* Near black (ink) */
--color-text-secondary: #5A5A5A;  /* Dark gray */
--color-accent-blue: #1E50A2;     /* FT Blue (authoritative) */
--color-accent-red: #D74850;      /* Financial red (alerts) */
--color-accent-green: #2E7D32;    /* Growth green */
--color-border: #E0DCC8;          /* Subtle border */
```

### Visual Elements
- **카드 디자인**: 얇은 테두리, 미세한 그림자 (box-shadow: 0 1px 3px rgba(0,0,0,0.08))
- **여백**: Generous spacing (padding: 1.5rem, gaps: 2rem)
- **선과 구분선**: 1px solid #E0DCC8 (subtle dividers)
- **데이터 시각화**: Clean charts with muted colors + strategic accents

### Layout Structure
```
┌─────────────────────────────────────────────────────────┐
│  Header: MEPPI Strategic Intelligence         [Search]  │
├─────────────────────────────────────────────────────────┤
│  Nav: Home | Channel | Competition | Promo | Regional │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Main Content Area                                      │
│  ┌────────────────────────────────────────────────┐    │
│  │  KPI Cards (4 columns)                        │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────┐ │    │
│  │  │3,245    │ │1,878    │ │11       │ │Alert│ │    │
│  │  │Phones   │ │Prices   │ │Countries│ │  3  │ │    │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────┘ │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Chart Area (Price Trends)                    │    │
│  │  [Interactive Line Chart]                     │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Data Table / Heatmap                         │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Technical Approach

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│  Browser (Hotwire)                                      │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Turbo Frames (Page Transitions)                │    │
│  │  • /dashboard/home → /dashboard/channel          │    │
│  └─────────────────────────────────────────────────┘    │
│                 │                                        │
│                 ▼                                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Stimulus Controllers (Interactivity)           │    │
│  │  • search_controller (Semantic Search)          │    │
│  │  • chart_controller (Chart.js updates)          │    │
│  │  • filter_controller (Country/Brand filters)    │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                         │ HTTP
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Rails Application (Web Mode)                           │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  DashboardController                            │    │
│  │  • home (KPI overview)                          │    │
│  │  • channel_strategy (Price comparison)          │    │
│  │  • competition (Market share)                   │    │
│  │  • promotions (Discount tracking)               │    │
│  │  • regional_prices (UAE benchmark)              │    │
│  └──────────────┬──────────────────────────────────┘    │
│                 │                                        │
│                 ▼                                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  DashboardService (Business Logic)              │    │
│  │  • fetch_home_stats                             │    │
│  │  • analyze_channel_strategy                     │    │
│  │  • calculate_market_share                       │    │
│  │  • track_promotions                             │    │
│  │  • compare_regional_prices                      │    │
│  └──────────────┬──────────────────────────────────┘    │
│                 │                                        │
│                 ▼                                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  PostgreSQL + pgvector                          │    │
│  │  • Phones (3,245 rows with embeddings)          │    │
│  │  • Prices (1,878 rows)                          │    │
│  │  • SemanticSearchService (RAG queries)          │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Implementation Strategy

#### Phase 1: Rails Configuration (30분)
1. **API-only 모드 해제**
   - `config/application.rb`: `config.api_only = false`
   - Gemfile에 frontend gems 추가
2. **Frontend Dependencies 추가**
   - `turbo-rails`
   - `stimulus-rails`
   - `tailwindcss-rails`
   - `chart.js` (via importmap)

#### Phase 2: Layout & Design System (1시간)
1. **Application Layout 구현**
   - Editorial grid layout
   - Playfair Display + Source Sans Pro 폰트
   - Navigation (5개 페이지)
2. **Tailwind Configuration**
   - Custom colors (FT Blue, Newsprint)
   - Font family 설정
   - Spacing tokens
3. **CSS Components**
   - KPI cards (`.kpi-card`)
   - Data tables (`.data-table`)
   - Chart containers (`.chart-container`)

#### Phase 3: Dashboard Pages (3시간)

##### Page 1: Home Dashboard (30분)
**Route**: `GET /dashboard/home`
**Components**:
- KPI Overview Cards (Total phones, prices, countries, alerts)
- Price Trends Chart (Line chart - 30 days)
- Regional Gaps Heatmap (UAE benchmark comparison)
- Top Price Movers Table

**Service Method**:
```ruby
DashboardService.home_stats(time_range_days: 30)
# Returns: {
#   overview: { total_phones, total_prices, countries, channels },
#   price_trends: { by_country, top_movers },
#   regional_gaps: { uae_violators, premium_chargers }
# }
```

##### Page 2: Channel Strategy (30분)
**Route**: `GET /dashboard/channel_strategy`
**Components**:
- Channel Price Comparison Table
- Efficiency Analysis (Margin, competitiveness)
- Recommended Channels (Badge system)
- Price Range Visualization

**Service Method**:
```ruby
ChannelStrategyService.analyze(phone_id, country_id)
# Returns: {
#   cheapest_channel,
#   price_range: { min, max, avg },
#   recommendations: [channel objects]
# }
```

##### Page 3: Competition Analysis (30분)
**Route**: `GET /dashboard/competition`
**Components**:
- Brand Market Share Donut Chart
- Model Price Positioning Map
- New Entrants Grid
- Competitive Intelligence Table

**Service Method**:
```ruby
CompetitionService.market_analysis(country_id)
# Returns: {
#   brand_shares: { Samsung: 45%, Apple: 30%, ... },
#   top_models,
#   new_entries
# }
```

##### Page 4: Promotions (30분)
**Route**: `GET /dashboard/promotions`
**Components**:
- Active Promotions List
- Discount Ranking (Bar chart)
- Date Range Filter
- Performance Metrics (Before/After prices)

**Service Method**:
```ruby
PromotionService.active_promotions(country_id)
# Returns: {
#   active: [promotion objects],
#   discount_ranking: [{ name, discount_pct }],
#   performance_metrics
# }
```

##### Page 5: Regional Prices (30분)
**Route**: `GET /dashboard/regional_prices`
**Components**:
- UAE Benchmark Monitoring
- Price Gap Heatmap (Country vs UAE)
- Alert List (30%+ underpriced channels)
- Benchmark Comparison Table

**Service Method**:
```ruby
RegionalPriceService.benchmark_analysis(phone_id)
# Returns: {
#   uae_benchmark,
#   local_prices: { country_id, price_usd, discount_pct },
#   alerts: [violators with 30%+ discount]
# }
```

#### Phase 4: Semantic Search UI (30분)
**Route**: `GET /dashboard/search`
**Components**:
- Natural Language Search Input (Stimulus controller)
- Search Results Grid (Turbo Frame)
- Similar Phones Suggestions

**Integration**:
- Existing `POST /api/v1/semantic_search` 엔드포인트 활용
- Stimulus controller로 검색 요청 처리

#### Phase 5: Testing & Polish (30분)
1. **Responsiveness Test**
   - Mobile (375px)
   - Tablet (768px)
   - Desktop (1440px+)
2. **Performance Optimization**
   - Image lazy loading
   - Chart.js lazy init
   - Turbo Frame caching
3. **Accessibility**
   - ARIA labels
   - Keyboard navigation
   - Screen reader support

## Dependencies

### Ruby Gems (추가 예정)
```ruby
# Frontend
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'importmap-rails'

# Charts (via JavaScript)
# chart.js (CDN 또는 importmap)
```

### JavaScript Libraries
- **Chart.js** (v4.4.0): 데이터 시각화
- **Turbo** (v7.3.0): 실시간 페이지 전환
- **Stimulus** (v3.2.0): 인터랙티브 컴포넌트

### External Services
- **BGE-M3 Server**: `http://127.0.0.1:8001` (Semantic search)
- **PostgreSQL**: Existing database

### Fonts
- **Playfair Display**: Google Fonts (Display)
- **Source Sans Pro**: Google Fonts (Body)
- **IBM Plex Mono**: Google Fonts (Monospace)

## Scope

### In Scope
- ✅ Rails API-only 모드 → Web 모드 전환
- ✅ 5개 페이지 뷰 구현
- ✅ Editorial 디자인 시스템 (Financial Times 스타일)
- ✅ Hotwire (Turbo + Stimulus) 통합
- ✅ Chart.js 데이터 시각화
- ✅ Semantic Search UI 통합
- ✅ 반응형 디자인 (Mobile/Tablet/Desktop)
- ✅ DashboardService 계층 구현

### Out of Scope
- ❌ 사용자 인증/권한 (Phase 4)
- ❌ 실시간 WebSocket 업데이트 (Action Cable)
- ❌ 데이터 export 기능 (CSV/PDF)
- ❌ 다크 모드
- ❌ 다국어 지원 (i18n)

## Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Rails Configuration | 30분 |
| 2 | Layout & Design System | 1시간 |
| 3 | Dashboard Pages (5 pages) | 2.5시간 |
| 4 | Semantic Search UI | 30분 |
| 5 | Testing & Polish | 30분 |

**Total Estimated Time**: 5시간

**Story Points**: 13sp (5일 = 1 sprint, assuming 1专注开发日/页面)

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| API-only 모드 전환 실패 | Low | High | config/application.rb 백업 후 진행 |
| Tailwind CSS 충돌 | Medium | Medium | 기존 CSS와 분리하여 진행 |
| Chart.js 성능 저하 | Low | Medium | 데이터 포인트 제한 (max 1000) |
| Editorial 디자인 일관성 | Medium | Low | Design System 문서화 + 공통 컴포넌트 |
| Turbo Frame 렌더링 이슈 | Low | Medium | Turbo Stream으로 fallback |

## Deliverables

1. **Configuration**
   - `config/application.rb` (API-only 제거)
   - `Gemfile` (Frontend gems 추가)
   - `config/importmap.rb` (Chart.js)

2. **Views**
   - `app/views/layouts/application.html.erb` (Editorial layout)
   - `app/views/dashboard/home.html.erb`
   - `app/views/dashboard/channel_strategy.html.erb`
   - `app/views/dashboard/competition.html.erb`
   - `app/views/dashboard/promotions.html.erb`
   - `app/views/dashboard/regional_prices.html.erb`
   - `app/views/dashboard/search.html.erb`

3. **Controllers**
   - `app/controllers/dashboard_controller.rb`
   - `app/controllers/semantic_search_controller.rb` (Web view)

4. **Services**
   - `app/services/dashboard_service.rb`
   - `app/services/channel_strategy_service.rb`
   - `app/services/competition_service.rb`
   - `app/services/promotion_service.rb`
   - `app/services/regional_price_service.rb`

5. **Styling**
   - `app/assets/stylesheets/application.tailwind.css`
   - `app/javascript/controllers/` (Stimulus controllers)
   - `app/javascript/charts/` (Chart.js configs)

6. **Tests**
   - `test/controllers/dashboard_controller_test.rb`
   - `test/services/dashboard_service_test.rb`
   - System tests (Turbo Frame interactions)

## Acceptance Criteria

### Functional
- [ ] 5개 페이지 모두 접근 가능
- [ ] KPI 카드에 실제 데이터 표시
- [ ] 차트가 반응형으로 렌더링
- [ ] Semantic Search가 자연어 쿼리로 작동
- [ ] 페이지 전환이 Turbo Frame으로 즉시 실행

### Design
- [ ] Playfair Display 폰트가 헤딩에 적용
- [ ] FT Blue (#1E50A2)가 강조 색상으로 사용
- [ ] 여백이 일관되게 적용 (padding: 1.5rem)
- [ ] 모바일에서 레이아웃이 단일 열로 변경

### Performance
- [ ] 페이지 로드 < 2초 (Lighthouse)
- [ ] 차트 렌더링 < 500ms
- [ ] Turbo Frame 전환 < 100ms

### Code Quality
- [ ] Vibe Coding 6원칙 준수
- [ ] Service Layer에 비즈니스 로직 분리
- [ ] View에 raw SQL 사용 금지
- [ ] Constants 추출 (색상, 폰트)

## Next Steps

1. **Design Document 생성**: `/pdca design rails-dashboard-ui`
2. **Implementation 시작**: `/pdca do rails-dashboard-ui`
3. **Gap Analysis**: `/pdca analyze rails-dashboard-ui` (구현 후)

---

**References**:
- Brainstorming: `docs/brainstorming/dashboard.md`
- Roadmap: `docs/ondev/20260210_01_meppe_rails_roadmap.md`
- Phase 2 Design: `docs/02-design/features/semantic-search-pgvector.design.md`
