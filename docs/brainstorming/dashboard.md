# MEPPI Dashboard 설계 방안 (Brainstorming)

## 📋 개요
- **대상**: Python Streamlit → Ruby on Rails 마이그레이션
- **사용자**: 경영진 (KPI 모니터링, 의사결정 지원)
- **핵심 지표**: 가격 동향, 지역별 격차
- **데이터**: 3,245폰, 1,878가격, 11개국가
- **업데이트**: 자동 일일 배치

---

## 1. 아키텍처 설계

### 1.1 백엔드/프론트분드 분리

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (Hotwire)                │
│  ┌───────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ Home Page │  │Charts    │  │  Channel     │  │
│  │ (Turbo)   │  │(Chart.js) │  │  Strategy    │  │
│  └───────────┘  └──────────┘  └──────────────┘  │
│  ┌───────────┐  ┌──────────┐  ┌──────────────┐  │
│  │Competition│  │Promotion│  │  Regional    │  │
│  │ Analysis  │  │ Tracker  │  │  Prices      │  │
│  └───────────┘  └──────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────┘
                         │
                         │ Turbo Frames + JSON API
                         ▼
┌─────────────────────────────────────────────────────┐
│                Backend (Rails API)                  │
│  ┌───────────────────────────────────────────────┐  │
│  │  Controllers │  ┌──────────┐  ┌──────────────┐  │
│  │  │ │  │Services  │  │Query Objects │ │  │
│  └──┴──────────────┴──────────┘  └──────────────┘  │
│  ┌───────────────────────────────────────────────┐  │
│  │  Models (ActiveRecord)                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │
│  │  │Countries│  │Channels  │  │  Phones  │  │  │
│  │  └──────────┘  └──────────┘  └──────────┘  │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                         │
                         │ PostgreSQL
                         ▼
┌─────────────────────────────────────────────────────┐
│              Database + pgvector                     │
│  • 3,245 Phones (with embeddings for RAG)             │
│  • 1,878 Prices                                         │
│  • 103 Channels                                        │
│  • 11 Countries                                        │
└─────────────────────────────────────────────────────┘
```

### 1.2 기술 스택 선택

**Frontend:**
- **Hotwire (Turbo + Stimulus)**: Rails의 기본 실시간 업데이트 프레임워크
- **Chart.js**: 반응형 차트 라이브러리
- **Tailwind CSS**: 스타일링 (또는 Bootstrap 5)
- **Importmap**: JavaScript 번들러 없이 Rails Asset Pipeline 사용

**Backend:**
- **Rails 7.1 API 모드**: JSON API 엔드포인트
- **PostgreSQL + pgvector**: Semantic RAG 지원
- **Sidekiq**: 백그라운드 job 처리 (일일 배치)

---

## 2. 페이지별 설계

### 2.1 Home Dashboard (메인)

**목적**: 경영진 핵심 KPI 한눈에 파악

**구성 요소:**
```ruby
# app/controllers/api/v1/dashboards_controller.rb
class Api::V1::DashboardsController < ApplicationController
  def home
    stats = StatsService.home_dashboard

    render json: {
      overview: {
        total_phones: stats[:total_phones],
        total_prices: stats[:total_prices],
        countries_covered: stats[:countries_count],
        channels_monitored: stats[:channels_count],
        latest_update: stats[:last_price_date]
      },
      price_trends: {
        by_country: stats[:avg_prices_by_country],
        top_movers: stats[:biggest_price_changes]
      },
      regional_gaps: {
        uae_benchmark_violators: stats[:underpriced_in_uae],
        premium_chargers: stats[:overpriced_regions]
      }
    }
  end
end
```

**UI 컴포넌트:**
- **KPI 카드**: 총 폰 수, 가격 데이터, 커버리지 국가
- **가격 동향 차트**: 국가별 평균 가격 추이 (선/막대 차트)
- **지역별 격차 히이블로 차트**: UAE 벤치마크 대비 저가/고가 현황
- **최대 가격 변동**: 최근 7일간 가격 변동 Top 10 폰

---

### 2.2 Channel Strategy (채널 전략)

**목적**: 최적 채널 믹스 추천

**기능:**
1. **채널별 가격 비교**: 동일 폰의 채널별 가격 비교 테이블
2. **효율성 분석**: 각 채널의 마진율, 경쟁력 분석
3. **추천 채널**: 데이터 기반 최적 채널 추천 알고리즘
   - 공식 리테일 → 온라인 → 통신사 우선순위
   - 가격 경쟁력 우위 채널 하이라이트

**데이터 로직:**
```ruby
# app/services/channel_strategy_service.rb
class ChannelStrategyService
  def analyze(phone_id, country_id)
    prices = Price.where(phone_id:, country_id:)

    {
      cheapest_channel: prices.order(:price_usd).first,
      price_range: {
        min: prices.minimum(:price_usd),
        max: prices.maximum(:price_usd),
        avg: prices.average(:price_usd)
      },
      recommendations: generate_recommendations(prices)
    }
  end

  private

  def generate_recommendations(prices)
    # 1. 최저가 채널이 20% 이상 저렴면 추천
    # 2. 공식 리테일보다 저렴면 추천
    # 3. 통신사 계약이 있으면 추가 분석
  end
end
```

---

### 2.3 Competition Analysis (경쟁사 분석)

**목적**: 경쟁사 동향 및 시장 점유율 파악

**기능:**
1. **브랜드별 점유율**: Samsung vs Apple vs Xiaomi 등 시장 점유율
2. **모델별 경쟁**: 특정 모델(예: S24 Ultra)의 채널별 가격 비교
3. **신규 진입 모델**: 최근 추가된 폰과 경쟁사 현황

**UI 컴포넌트:**
- **브랜드 도넛 차트**: 시장 점유율 파이 차트
- **폰별 가격 포지션**: Map/히트맵으로 시각화
- **경쟁사 그리드**: 채널별 경쟁사가 매트릭스 형태

---

### 2.4 Promotions (프로모션)

**목적**: 진행 중인 프로모션 효과 추적

**기능:**
1. **활성 프로모션 목록**: 현재 진행 중인 모든 프로모션
2. **할인율 랭킹**: 프로모션별 할인율 비교
3. **기간별 필터**: 주간/월별 프로모션 필터링
4. **성과 지표**: 프로모션 기간 가격 변화 추적

**데이터 모델:**
```ruby
# app/models/promotion.rb
class Promotion < ApplicationRecord
  scope :active, -> { where('valid_until >= ?', Date.today) }

  def discount_percentage
    return 0 unless discount_amount_local.present? && price_before.present?
    ((discount_amount_local / price_before) * 100).round(2)
  end
end
```

---

### 2.5 Regional Prices (지역별 가격)

**목적**: 지역별 가격 격차와 벤치마크 모니터링

**핵심 기능: UAE DubaiBenchmark 모니터링**

**벤치마크 계산 로직:**
```ruby
# app/services/regional_price_service.rb
class RegionalPriceService
  DUBAI_VAT_RATE = 0.05  # 5%

  def analyze_underpricing(phone_id, country_id)
    phone = Phone.find(phone_id)

    # 1. UAE 최저가 (VAT 제외)
    dubai_wholesale = DubaiBenchmark.where(phone_id:).latest&.price_wholesale

    # 2. 현재 국가의 최저가 (USD 환산)
    local_price_usd = Price
      .where(phone_id:)
      .joins(:channel)
      .where(channels: { country_id: })
      .minimum(:price_usd)

    # 3) 얼마나 싼게 저렴는지 계산
    discount_percent = ((dubai_wholesale - local_price_usd) / dubai_wholesale * 100).round(2)

    {
      phone: phone.full_name,
      local_price_usd:,
      dubai_benchmark: dubai_wholesale,
      discount_percent:,
      status: discount_status(discount_percent)
    }
  end

  # 30% 이상 싸면 가격 조치 필요
  def discount_status(percent)
    return '정상' if percent < 20
    return '주의' if percent < 30
    '심각'  # 30%+ 싸게 저렴
  end
end
```

**UI 시각화:**
- **히트맵**: 국가별 가격 수준 (색상: 녹색-정상, 빨강-주의, 빨초-심각)
- **벤치마크 대비 테이블**: UAE Amazon 대비 싼게율
- **Alert 리스트**: 30% 이상 싼게 책정 채널 표시

---

## 3. Semantic RAG 아키텍처

### 3.1 pgvector 스키마

```ruby
# db/migrate/20260210_add_embeddings.rb
class AddEmbeddingsToPhones < ActiveRecord::Migration[7.1]
  def change
    # pgvector 확장 활성화
    enable_extension 'vector'

    # Phones 테이블에 embedding 컬럼 추가
    add_column :phones, :embedding, :vector, limit: 1536  # OpenAI text-embedding-3-small
    add_column :prices, :embedding, :vector, limit: 1536

    # 코사인 유사도 검색을 위한 인덱스
    add_index :phones, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
    add_index :prices, :embedding, using: :ivfflat, :controller => :vector_cosine_ops
  end
end
```

### 3.2 Phone 모델에 RAG 연동

```ruby
# app/models/phone.rb
class Phone < ApplicationRecord
  # pgvector gem 사용
  has_neighbors :embedding

  def self.semantic_search(query_text, limit: 10)
    # 1. 쿼리에서 텍스트 임베딩 생성 (OpenAI API)
    query_embedding = OpenAiService.embed(query_text)

    # 2. 코사인 유사도 검색
    nearest_neighbors = Neighborhood.nearest(
      :embedding,
      query_embedding,
      limit:
    ).to_a

    nearest_neighbors
  end

  def self.find_similar(phone_id, limit: 5)
    phone = Phone.find(phone_id)

    # 해당 폰과 유사한 폰 검색
    phone.neighbor(:embedding, limit:)
  end
end
```

### 3.3 RAG 활용 시나리오

**시나리오 1: 자연어 폰 검색**
```
사용자 입력: "삼성 갤럭시 S24 자켜 추천"
→ RAG: 자연어 검색으로 Samsung Galaxy S24 시리즈 추천
→ 응답: 검색된 폰 목록 + 각 폰의 최저가
```

**시나리오 2: 가격 패턴 인사이트**
```
질문: "UAE에서 최근 가격이 급락하는 폰들은?"
→ RAG: 벡터 유사도 기반으로 가격 하락 폰 추천
→ 응답: 가격 하락 추세 폰 10개 + 원인 분석
```

**시나리오 3: 지역별 브랜드 모니터링**
```
질문: "Pakistan에서 Samsung 폰 가격이 너무 낮은 채널 있어?"
→ RAG: 가격 데이터와 텍스트 임베딩 결합
→ 응답: 위반 채널 리스트 + 정책 제안
```

---

## 4. 데이터 업데이트 아키텍처

### 4.1 일일 배치 시스템

**Sidekiq 설정:**
```ruby
# config/sidekiq.yml
:concurrency: 5  # 5개 워커 동시 실행
:queues:
  - [scraping, 3]
  - [default, 2]

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

# 매일 새벽 오전 2시에 스크래핑 실행
Sidekiq::Cron::Job.load_from_hash(
  'scrape_all_prices' => {
    'class' => 'ScrapeAllPricesJob',
    'cron' => '0 2 * * *',  # 매일 02:00
    'queue' => 'scraping'
  }
)
```

### 4.2 배치 잡 구조

```ruby
# app/jobs/scrape_all_prices_job.rb
class ScrapeAllPricesJob < ApplicationJob
  queue_as :scraping

  def perform(*args)
    results = []

    # 1. 각 국가별로 스크래핑 실행
    Country.active.each do |country|
      country.channels.active.each do |channel|
        results << ScrapeChannelJob.perform_later(channel.id, country.id)
      end
    end

    # 2. 임베딩 생성 (RAG용)
    GenerateEmbeddingsJob.perform_later if results.present?
  end
rescue => e
    Rails.logger.error "Scraping failed: #{e.message}"
    # Slack/Email 알림
  end
end
```

### 4.3 데이터 동기화 흐름

```
1. 스크래핑 (02:00)
   ├─ 각 채널별 가격 수집
   ├─ 원본 데이터 DB 업데이트
   └─ 임베딩 생성

2. 가격 분석 (02:30)
   ├─ 지역별 평균 계산
   ├─ 벤치마크 대비
   └─ 이상치 탐지

3. 알림 (03:00)
   ├─ 경영진 대시보드 갱신
   └─ 이상 징후 후 알림
```

---

## 5. UI/UX 설계

### 5.1 레이아웃

**목표: 경영진이 5분내 모든 핵심 정보 확인 가능

**화면 구성:**
```
┌────────────────────────────────────────────────────────┐
│  MEPPI Strategic Intelligence                      [logo]        │
├────────────────────────────────────────────────────────┤
│                                                        │
│  📊 Overview            💰 Price Trends               │
│  ┌────────┐            ┌────────────┐              │
│  │3,245폰 │            │국가별 추이│              │
│  │1,878가격│            └────────────┘              │
│  └────────┘                                        │
│  ⚠️  대시보어: 3개 채널 가격 이상                   │
│  📈 최근 업데이트: 5분 전                          │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │                지역별 가격 비교                    │  │
│  │  [히트맵 표시]                                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  🔍 검색: [폰 검색창...................] 📅 [필터]  │
└────────────────────────────────────────────────────────┘
```

### 5.2 인터랙티브 차트

**기능:**
- **필터**: 국가, 브랜드, 채널 타입, 가격 범위
- **정렬**: 가격순, 최신순, 할인율순
- **내보도 토글**: 클릭 시 상세 정보 모달 (Turbo Frame)

---

## 6. 기술 구현 상세

### 6.1 Controller 구조

```ruby
# app/controllers/api/v1/dashboards_controller.rb
class Api::V1::DashboardsController < ApplicationController
  before_action :set_time_range, only: [:home]

  def home
    @dashboard = DashboardPresenter.new(@time_range)

    render json: {
      overview: @dashboard.overview,
      price_trends: @dashboard.price_trends,
      regional_gaps: @dashboard.regional_gaps,
      alerts: @dashboard.alerts
    }
  end

  private

  def set_time_range
    @time_range = params[:period]&.to_i || 30  # 기본 30일
  end
end
```

### 6.2 Service Layer

```ruby
# app/services/dashboard_service.rb
class DashboardService
  def home_dashboard(time_range_days = 30)
    start_date = time_range_days.days.ago.to_date

    {
      overview: overview_stats,
      price_trends: calculate_price_trends(start_date),
      regional_gaps: analyze_regional_gaps,
      alerts: generate_alerts
    }
  end

  private

  def overview_stats
    {
      total_phones: Phone.count,
      total_prices: Price.where('date >= ?', 30.days.ago).count,
      countries_covered: Country.active.count,
      channels_monitored: Channel.active.count,
      last_update: Price.maximum(:date)
    }
  end

  def analyze_regional_gaps
    # 벤치마크 대비 30% 이상 싼은 경우 Alert
    underpriced_channels = Price
      .joins(:channel)
      .group('channels.id')
      .having('MIN(price_usd) < ?', benchmark_price * 0.7)
      .includes(:channel)

    underpriced_channels.map do |price, channel|
      {
        channel: channel.name,
        phone: price.phone.full_name,
        discount_percent: calculate_discount(price, benchmark_price)
      }
    end
  end
end
```

### 6.3 RAG Service

```ruby
# app/services/semantic_search_service.rb
class SemanticSearchService
  def initialize
    @client = OpenAI::Client.new
  end

  def search_phones(query, country_id: nil, limit: 10)
    # 1. 쿼리 임베딩 생성
    query_embedding = generate_embedding(query)

    # 2. pgvector 유사도 검색
    similar_phones = Phone.neighbor(
      :embedding,
      query_embedding,
      limit:
    )

    # 3. 가격 데이터 조인
    phone_ids = similar_phones.pluck(:id)
    prices = Price.where(phone_id: phone_ids)

    # 4. 국가 필터링
    prices = prices.joins(:channel).where(channels: { country_id: }) if country_id

    {
      results: format_results(similar_phones, prices),
      query: query,
      total_found: similar_phones.count
    }
  end

  private

  def generate_embedding(text)
    response = @client.embeddings.create(
      model: 'text-embedding-3-small',
      input: text
    )
    response.digests.first.embedding
  end
end
```

---

## 7. 성능 최적화

### 7.1 캐싱 전략

```ruby
# app/services/query_optimizer_service.rb
class QueryOptimizerService
  # N+1 Query 방지
  def optimize_price_query(prices)
    prices.includes(:phone, :channel)

    # Counter Cache 활용
    Rails.cache.fetch("stats_#{Date.today}", expires_in: 12.hours) do
      calculate_daily_stats
    end
  end
end
```

### 7.2 인덱스 전략

```ruby
# db/migrate/xxx_add_performance_indexes.rb
# 복합 인덱스
add_index :prices, [:phone_id, :date, :price_usd], name: 'idx_prices_lookup'
add_index :prices, [:channel_id, :date], name: 'idx_prices_channel_date'

# partial index for recent data
add_index :prices, [:date], name: 'idx_prices_recent',
  where: 'date >= CURRENT_DATE - INTERVAL \'90 days\''
```

---

## 8. 보안 고려사항

### 8.1 API 인증

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    # API Key 또는 JWT 기반 인증
    header_token = request.headers['Authorization']&.to_s
    User.find_by(api_token: header_token) || render_unauthorized
  end
end
```

### 8.2 Rate Limiting

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/v1/')
  end
end
```

---

## 9. 다음 단계

### Phase 1: 기본 구현 (2주)
- [ ] 5개 페이지 기본 뷰 템플릿 구현
- [ ] 차트 라이브러리 연동
- [ ] 기본 API 완성

### Phase 2: Semantic RAG (1주)
- [ ] pgvector 설치 및 마이그레이션
- [ ] 임베딩 생성 서비스
- [ ] 자연어 검색 API

### Phase 3: 일일 배치 (1주)
- [ ] Sidekiq 설정
- [ ] 스크래핑 스케줄러 작성
- [ ] 배치 모니터링

### Phase 4: UI 개선 (1주)
- [ ] Hotwire 실시간 업데이트
- [ ] Turbo Frame으로 페이지 전환
- [ ] 반응형 디자인 적용

---

## 10. 기술 의사결

| 항목 | 선택 | 이유 |
|------|------|------|
| Frontend | **Hotwire** | Rails 네이티브, 번들리 필요 없음 |
| CSS | **Tailwind CSS** | 빠른 개발, 반응형 |
| Charts | **Chart.js** | 가볍고 강력, Rails 친화 |
| Job 처리 | **Sidekiq** | Rails 표준, 안정적 |
| 검색 | **pgvector** | PostgreSQL 네이티브, RAG에 최적 |

---

**다음 단계**: Phase 1 시작 - 기본 뷰템플릿 구현
