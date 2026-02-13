# Design: Rails Dashboard UI Implementation

**Feature**: rails-dashboard-ui
**Created**: 2026-02-11
**Phase**: Design
**Status**: Ready for Implementation
**Design Direction**: Editorial (Financial Times style)

---

## System Architecture

### Full-Stack Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser Layer                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  UI Components (Editorial Design)                          │ │
│  │  • Typography: Playfair Display (h1-h3)                   │ │
│  │  • Colors: FT Blue, Newsprint, Ink                        │ │
│  │  • Layout: Grid-based, generous spacing                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                  │                              │
│  ┌─────────────────────────────────▼──────────────────────────┐ │
│  │  Hotwire (Turbo + Stimulus)                                │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Turbo Frames                                        │  │ │
│  │  │  • Page transitions without full reload              │  │ │
│  │  │  • Lazy loading heavy components                     │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Stimulus Controllers                               │  │ │
│  │  │  • search_controller: Semantic search input          │  │ │
│  │  │  • chart_controller: Chart.js lifecycle             │  │ │
│  │  │  • filter_controller: Country/Brand filters          │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────┬──────────────────────────┘ │
└────────────────────────────────────┼─────────────────────────────┘
                                     │ HTTP/JSON
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Rails Application Layer                     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Routing (config/routes.rb)                               │ │
│  │  GET  /dashboard → #home                                  │ │
│  │  GET  /dashboard/channel_strategy → #channel_strategy     │ │
│  │  GET  /dashboard/competition → #competition               │ │
│  │  GET  /dashboard/promotions → #promotions                 │ │
│  │  GET  /dashboard/regional_prices → #regional_prices       │ │
│  │  GET  /dashboard/search → #search                         │ │
│  └──────────────────────────┬─────────────────────────────────┘ │
│                             │                                   │
│  ┌──────────────────────────▼─────────────────────────────────┐ │
│  │  DashboardController                                     │ │
│  │  • home: Fetch overview stats, price trends              │ │
│  │  • channel_strategy: Channel comparison data             │ │
│  │  • competition: Market share analysis                    │ │
│  │  • promotions: Active promotions tracking                │ │
│  │  • regional_prices: UAE benchmark monitoring             │ │
│  │  • search: Semantic search UI                            │ │
│  └──────────────────────────┬─────────────────────────────────┘ │
│                             │                                   │
│  ┌──────────────────────────▼─────────────────────────────────┐ │
│  │  Service Layer (Business Logic)                           │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  DashboardService                                    │  │ │
│  │  │  • home_stats(time_range) → Hash                    │  │ │
│  │  │  • price_trends(start_date, end_date) → Array       │  │ │
│  │  │  • regional_gaps → Array                            │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  ChannelStrategyService                              │  │ │
│  │  │  • analyze(phone_id, country_id) → Hash             │  │ │
│  │  │  • cheapest_channels(country_id) → Array            │  │ │
│  │  │  • price_range(phone_id) → Hash                     │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  CompetitionService                                  │  │ │
│  │  │  • market_share(country_id) → Hash                  │  │ │
│  │  │  • brand_distribution → Hash                        │  │ │
│  │  │  • top_models(limit) → Array                        │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  PromotionService                                    │  │ │
│  │  │  • active_promotions → Array                         │  │ │
│  │  │  • discount_ranking → Array                          │  │ │
│  │  │  • performance_metrics → Hash                       │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  RegionalPriceService                                │  │ │
│  │  │  • benchmark_analysis(phone_id) → Hash               │  │ │
│  │  │  • underpricing_alerts → Array                       │  │ │
│  │  │  • country_comparison → Array                       │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────┬─────────────────────────────────┘ │
└──────────────────────────────┼─────────────────────────────────────┘
                               │ ActiveRecord/PG
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Data Layer (PostgreSQL)                      │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  phones (3,245 rows)                                       │ │
│  │  • id, brand, model, url, display_type, storage, ram      │ │
│  │  • embedding vector(1024)  -- pgvector                     │ │
│  │  • INDEX: embedding ivfflat (cosine)                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  prices (1,878 rows)                                       │ │
│  │  • id, phone_id, channel_id, price_usd, date              │ │
│  │  • INDEX: (phone_id, date), (channel_id, date)            │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  channels (103 rows)                                       │ │
│  │  • id, name, url, channel_type, country_id                │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  countries (11 rows)                                       │ │
│  │  • id, name, code, currency_code                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Semantic Search: SemanticSearchService.search_phones()         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Design System: Editorial Financial Times Style

### Typography System

```css
/* Font Families */
--font-display: 'Playfair Display', Georgia, 'Times New Roman', serif;
--font-body: 'Source Sans Pro', -apple-system, BlinkMacSystemFont, sans-serif;
--font-mono: 'IBM Plex Mono', 'SF Mono', 'Monaco', monospace;

/* Font Sizes (Type Scale - 1.250 Major Third) */
--text-xs: 0.640rem;    /* 10.24px */
--text-sm: 0.800rem;    /* 12.8px */
--text-base: 1.000rem;  /* 16px */
--text-lg: 1.250rem;    /* 20px */
--text-xl: 1.563rem;    /* 25px */
--text-2xl: 1.953rem;   /* 31.25px */
--text-3xl: 2.441rem;   /* 39.06px */
--text-4xl: 3.052rem;   /* 48.83px */

/* Font Weights */
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;

/* Line Heights */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### Color Palette

```css
/* Primary Colors */
--color-bg-primary: #FDFBF7;      /* Newsprint off-white */
--color-bg-secondary: #F5F2EA;    /* Slightly darker newsprint */
--color-bg-tertiary: #EAE8DF;     /* Card background */

/* Text Colors */
--color-text-primary: #1A1A1A;    /* Near black (ink) */
--color-text-secondary: #5A5A5A;  /* Dark gray */
--color-text-tertiary: #8A8A8A;   /* Medium gray */
--color-text-inverse: #FFFFFF;    /* White */

/* Accent Colors */
--color-accent-blue: #1E50A2;     /* FT Blue (authoritative) */
--color-accent-blue-light: #4A7BC4;
--color-accent-red: #D74850;      /* Financial red (alerts) */
--color-accent-green: #2E7D32;    /* Growth green */
--color-accent-amber: #F59E0B;    /* Warning */
--color-accent-purple: #7C3AED;   /* Special highlight */

/* Border & Divider */
--color-border: #E0DCC8;          /* Subtle border */
--color-divider: #D4D0C8;         /* Section divider */

/* Semantic Colors */
--color-success: #2E7D32;
--color-warning: #F59E0B;
--color-error: #D74850;
--color-info: #1E50A2;
```

### Spacing System

```css
/* Base Unit: 0.25rem (4px) */
--space-1: 0.250rem;  /* 4px */
--space-2: 0.500rem;  /* 8px */
--space-3: 0.750rem;  /* 12px */
--space-4: 1.000rem;  /* 16px */
--space-5: 1.250rem;  /* 20px */
--space-6: 1.500rem;  /* 24px */
--space-8: 2.000rem;  /* 32px */
--space-10: 2.500rem; /* 40px */
--space-12: 3.000rem; /* 48px */
--space-16: 4.000rem; /* 64px */
```

### Component Styles

#### KPI Card

```css
.kpi-card {
  background: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: 4px;
  padding: var(--space-6);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  transition: box-shadow 0.2s ease;
}

.kpi-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.kpi-card__label {
  font-family: var(--font-body);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: var(--space-2);
}

.kpi-card__value {
  font-family: var(--font-display);
  font-size: var(--text-3xl);
  font-weight: var(--font-bold);
  color: var(--color-text-primary);
  line-height: var(--leading-tight);
}

.kpi-card__trend {
  font-family: var(--font-body);
  font-size: var(--text-sm);
  margin-top: var(--space-2);
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.kpi-card__trend--up {
  color: var(--color-accent-green);
}

.kpi-card__trend--down {
  color: var(--color-accent-red);
}
```

#### Data Table

```css
.data-table {
  width: 100%;
  border-collapse: collapse;
  font-family: var(--font-body);
}

.data-table__header {
  border-bottom: 2px solid var(--color-text-primary);
}

.data-table__header-cell {
  font-family: var(--font-display);
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  color: var(--color-text-primary);
  text-align: left;
  padding: var(--space-3) var(--space-4);
}

.data-table__row {
  border-bottom: 1px solid var(--color-border);
  transition: background 0.15s ease;
}

.data-table__row:hover {
  background: var(--color-bg-secondary);
}

.data-table__cell {
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  color: var(--color-text-primary);
  padding: var(--space-3) var(--space-4);
}

.data-table__cell--text {
  font-family: var(--font-body);
}
```

#### Chart Container

```css
.chart-container {
  background: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: 4px;
  padding: var(--space-6);
  height: 400px;
  position: relative;
}

.chart-container__title {
  font-family: var(--font-display);
  font-size: var(--text-xl);
  font-weight: var(--font-bold);
  color: var(--color-text-primary);
  margin-bottom: var(--space-4);
}

.chart-container__legend {
  display: flex;
  justify-content: center;
  gap: var(--space-6);
  margin-top: var(--space-4);
}

.chart-container__legend-item {
  font-family: var(--font-body);
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  gap: var(--space-2);
}
```

---

## API Specifications

### Dashboard Controller

#### GET /dashboard/home

**Description**: Fetch home dashboard statistics including KPI overview, price trends, and regional gaps.

**Request Parameters**:
```ruby
# Optional query parameters
period: Integer  # Time range in days (default: 30)
```

**Response Format**:
```json
{
  "overview": {
    "total_phones": 3245,
    "total_prices": 1878,
    "countries_count": 11,
    "channels_count": 103,
    "latest_update": "2026-02-11T02:30:00Z"
  },
  "price_trends": {
    "by_country": [
      {
        "country": "United Arab Emirates",
        "avg_price": 899.99,
        "trend": "up",
        "change_percent": 5.2
      }
    ],
    "top_movers": [
      {
        "phone": "Samsung Galaxy S24 Ultra",
        "price_change": -150.00,
        "change_percent": -15.5,
        "previous_price": 969.00,
        "current_price": 819.00
      }
    ]
  },
  "regional_gaps": {
    "uae_violators": [
      {
        "phone": "iPhone 15 Pro Max",
        "country": "Saudi Arabia",
        "channel": "Amazon.sa",
        "local_price": 799.00,
        "uae_benchmark": 1199.00,
        "discount_percent": 33.4,
        "status": "critical"
      }
    ],
    "premium_chargers": [
      {
        "phone": "Samsung Galaxy S24 Ultra",
        "country": "United Kingdom",
        "channel": "Carphone Warehouse",
        "local_price": 1149.00,
        "uae_benchmark": 999.00,
        "premium_percent": 15.0
      }
    ]
  }
}
```

**Service Method**:
```ruby
# app/services/dashboard_service.rb
class DashboardService
  def self.home_stats(time_range_days: 30)
    start_date = time_range_days.days.ago.to_date

    {
      overview: overview_stats,
      price_trends: calculate_price_trends(start_date),
      regional_gaps: analyze_regional_gaps
    }
  end

  private

  def self.overview_stats
    {
      total_phones: Phone.count,
      total_prices: Price.where('date >= ?', 30.days.ago).count,
      countries_count: Country.count,
      channels_count: Channel.count,
      latest_update: Price.maximum(:date)
    }
  end

  def self.calculate_price_trends(start_date)
    prices_by_country = Price
      .where('date >= ?', start_date)
      .joins(:channel)
      .group('channels.country_id')
      .average(:price_usd)

    # Transform to response format
    # ...
  end

  def self.analyze_regional_gaps
    # Compare against UAE benchmark
    # Return violators (>30% discount) and premium chargers
    # ...
  end
end
```

---

#### GET /dashboard/channel_strategy

**Description**: Channel price comparison and strategy recommendations.

**Request Parameters**:
```ruby
phone_id: Integer    # Required
country_id: Integer  # Optional
```

**Response Format**:
```json
{
  "phone": {
    "id": 389,
    "full_name": "Samsung Galaxy S24 Ultra",
    "brand": "Samsung",
    "model": "Galaxy S24 Ultra"
  },
  "price_range": {
    "min": 819.00,
    "max": 1149.00,
    "avg": 999.00,
    "spread_percent": 40.3
  },
  "channels": [
    {
      "id": 12,
      "name": "Amazon UAE",
      "channel_type": "online",
      "price_usd": 849.00,
      "is_cheapest": true,
      "discount_from_avg": 15.0,
      "recommendation": "best_value"
    },
    {
      "id": 15,
      "name": "Carphone Warehouse",
      "channel_type": "official_brand",
      "price_usd": 999.00,
      "is_cheapest": false,
      "discount_from_avg": 0.0,
      "recommendation": "standard"
    }
  ],
  "recommendations": [
    {
      "channel_id": 12,
      "reason": "Lowest price with reliable delivery",
      "priority": "high"
    }
  ]
}
```

**Service Method**:
```ruby
# app/services/channel_strategy_service.rb
class ChannelStrategyService
  def self.analyze(phone_id, country_id: nil)
    phone = Phone.find(phone_id)

    prices = Price
      .where(phone_id:)
      .joins(:channel)
      .then { |scope| country_id ? scope.where(channels: { country_id }) : scope }

    price_range = calculate_price_range(prices)
    channel_data = build_channel_data(prices)
    recommendations = generate_recommendations(channel_data, price_range)

    {
      phone: phone_serializer(phone),
      price_range:,
      channels: channel_data,
      recommendations:
    }
  end

  private

  def self.calculate_price_range(prices)
    {
      min: prices.minimum(:price_usd),
      max: prices.maximum(:price_usd),
      avg: prices.average(:price_usd).to_f.round(2),
      spread_percent: calculate_spread(prices)
    }
  end

  def self.build_channel_data(prices)
    prices.includes(:channel).map do |price|
      {
        id: price.channel.id,
        name: price.channel.name,
        channel_type: price.channel.channel_type,
        price_usd: price.price_usd,
        is_cheapest: false, # Will be calculated
        discount_from_avg: 0.0,
        recommendation: determine_recommendation(price)
      }
    end
  end

  def self.generate_recommendations(channels, price_range)
    cheapest = channels.min_by { |c| c[:price_usd] }
    avg_price = price_range[:avg]

    channels.filter do |ch|
      # Recommend if >20% cheaper than average
      ch[:price_usd] < (avg_price * 0.8)
    end.map do |ch|
      {
        channel_id: ch[:id],
        reason: "Price is #{((avg_price - ch[:price_usd]) / avg_price * 100).round(1)}% below average",
        priority: ch[:price_usd] < (avg_price * 0.7) ? :high : :medium
      }
    end
  end
end
```

---

#### GET /dashboard/competition

**Description**: Market analysis including brand share and competitive positioning.

**Request Parameters**:
```ruby
country_id: Integer  # Optional
```

**Response Format**:
```json
{
  "market_share": {
    "Samsung": 45.2,
    "Apple": 30.1,
    "Xiaomi": 12.5,
    "Oppo": 7.3,
    "Vivo": 4.9
  },
  "top_models": [
    {
      "phone": "Samsung Galaxy S24 Ultra",
      "price_avg": 950.00,
      "market_position": "premium",
      "competitor_count": 8
    }
  ],
  "new_entries": [
    {
      "phone": "iPhone 16 Pro",
      "first_seen": "2026-02-01",
      "channels": 12
    }
  ]
}
```

**Service Method**:
```ruby
# app/services/competition_service.rb
class CompetitionService
  def self.market_analysis(country_id: nil)
    {
      market_share: calculate_brand_share(country_id),
      top_models: get_top_models(country_id),
      new_entries: get_new_entries(country_id)
    }
  end

  private

  def self.calculate_brand_share(country_id)
    query = Phone.joins(:prices)
    query = query.joins(:channel).where(channels: { country_id }) if country_id

    # Count phones by brand
    query.group(:brand).count.transform_values do |count|
      (count.to_f / Phone.count * 100).round(1)
    end
  end
end
```

---

#### GET /dashboard/promotions

**Description**: Active promotions tracking and discount analysis.

**Response Format**:
```json
{
  "active_promotions": [
    {
      "id": 1,
      "phone": "Samsung Galaxy S24 Ultra",
      "channel": "Amazon UAE",
      "original_price": 1149.00,
      "discounted_price": 949.00,
      "discount_percent": 17.4,
      "valid_until": "2026-02-28",
      "days_remaining": 17
    }
  ],
  "discount_ranking": [
    {
      "phone": "iPhone 15 Pro Max",
      "max_discount": 25.0,
      "channel": "Noon"
    }
  ]
}
```

---

#### GET /dashboard/regional_prices

**Description**: UAE benchmark monitoring and regional price comparison.

**Request Parameters**:
```ruby
phone_id: Integer  # Optional (if omitted, shows aggregate view)
```

**Response Format**:
```json
{
  "uae_benchmark": {
    "phone": "Samsung Galaxy S24 Ultra",
    "wholesale_price": 750.00,
    "retail_price": 999.00,
    "vat_included": true,
    "vat_rate": 0.05
  },
  "regional_comparison": [
    {
      "country": "Saudi Arabia",
      "local_price": 849.00,
      "uae_equivalent": 999.00,
      "discount_percent": 15.0,
      "status": "warning"
    }
  ],
  "alerts": [
    {
      "phone": "iPhone 15 Pro Max",
      "country": "Pakistan",
      "channel": "Daraz",
      "discount_percent": 35.5,
      "status": "critical",
      "action_required": true
    }
  ]
}
```

**Service Method**:
```ruby
# app/services/regional_price_service.rb
class RegionalPriceService
  DUBAI_VAT_RATE = 0.05
  CRITICAL_THRESHOLD = 30  # percent

  def self.benchmark_analysis(phone_id = nil)
    if phone_id
      analyze_single_phone(phone_id)
    else
      aggregate_analysis
    end
  end

  private

  def self.analyze_single_phone(phone_id)
    phone = Phone.find(phone_id)
    uae_benchmark = get_uae_benchmark(phone_id)

    regional_comparison = Country.all.map do |country|
      local_price = Price
        .joins(:channel)
        .where(phone_id:, channels: { country_id: country.id })
        .minimum(:price_usd)

      next unless local_price

      discount_percent = calculate_discount(local_price, uae_benchmark[:retail_price])

      {
        country: country.name,
        local_price:,
        uae_equivalent: uae_benchmark[:retail_price],
        discount_percent: discount_percent.round(1),
        status: discount_status(discount_percent)
      }
    end.compact

    alerts = regional_comparison.select { |rc| rc[:discount_percent] >= CRITICAL_THRESHOLD }

    {
      uae_benchmark:,
      regional_comparison:,
      alerts:
    }
  end

  def self.discount_status(percent)
    return :normal if percent < 20
    return :warning if percent < CRITICAL_THRESHOLD
    :critical
  end

  def self.calculate_discount(local_price, uae_price)
    ((uae_price - local_price) / uae_price * 100).round(1)
  end
end
```

---

#### GET /dashboard/search

**Description**: Semantic search UI for natural language phone search.

**Implementation**:
- Uses existing `POST /api/v1/semantic_search` endpoint
- Stimulus controller handles form submission
- Turbo Frame updates results without page reload

**Stimulus Controller**:
```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from '@hotwired/stimulus';
import { Turbo } from '@hotwired/turbo-rails';

export default class extends Controller {
  static targets = ['input', 'results', 'loading'];
  static values = { url: String };

  search(event) {
    event.preventDefault();

    const query = this.inputTarget.value.trim();
    if (query.length < 2) return;

    this.showLoading();

    fetch('/api/v1/semantic_search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify({ query, limit: 10 })
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html);
      this.hideLoading();
    })
    .catch(error => {
      console.error('Search failed:', error);
      this.hideLoading();
    });
  }

  showLoading() {
    this.loadingTarget.classList.remove('hidden');
  }

  hideLoading() {
    this.loadingTarget.classList.add('hidden');
  }
}
```

---

## Component Specifications

### 1. Application Layout

**File**: `app/views/layouts/application.html.erb`

```erb
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MEPPI Strategic Intelligence</title>

  <!-- Google Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=Playfair+Display:wght@400;600;700&family=Source+Sans+Pro:wght@400;500;600&display=swap" rel="stylesheet">

  <!-- Tailwind CSS -->
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>

  <!-- JavaScript -->
  <%= javascript_importmap_tags %>
</head>

<body class="bg-bg-primary text-text-primary font-body antialiased">
  <%= render 'shared/header' %>
  <%= render 'shared/navigation' %>

  <main class="container mx-auto px-4 py-8">
    <%= yield %>
  </main>

  <%= render 'shared/footer' %>
</body>
</html>
```

---

### 2. Home Dashboard View

**File**: `app/views/dashboard/home.html.erb`

```erb
<div class="space-y-8">
  <!-- Page Header -->
  <header class="border-b border-border pb-4">
    <h1 class="font-display text-4xl font-bold text-text-primary">
      Dashboard Overview
    </h1>
    <p class="font-body text-text-secondary mt-2">
      Last updated: <%= @dashboard[:overview][:latest_update].strftime("%B %d, %Y at %H:%M") %>
    </p>
  </header>

  <!-- KPI Cards -->
  <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
    <%= render 'shared/kpi_card',
      label: "Total Phones",
      value: number_with_delimiter(@dashboard[:overview][:total_phones]),
      trend: nil %>

    <%= render 'shared/kpi_card',
      label: "Price Data Points",
      value: number_with_delimiter(@dashboard[:overview][:total_prices]),
      trend: nil %>

    <%= render 'shared/kpi_card',
      label: "Countries Covered",
      value: @dashboard[:overview][:countries_count].to_s,
      trend: nil %>

    <%= render 'shared/kpi_card',
      label: "Active Alerts",
      value: @dashboard[:regional_gaps][:uae_violators].length.to_s,
      trend: nil,
      status: @dashboard[:regional_gaps][:uae_violators].any? ? :warning : :normal %>
  </section>

  <!-- Price Trends Chart -->
  <section class="chart-container">
    <h2 class="chart-container__title">Price Trends (30 Days)</h2>
    <canvas id="priceTrendsChart" data-chart="<%= @dashboard[:price_trends].to_json %>"></canvas>
  </section>

  <!-- Top Price Movers Table -->
  <section>
    <h2 class="font-display text-2xl font-bold text-text-primary mb-4">
      Top Price Movers
    </h2>
    <%= render 'shared/data_table',
      headers: ['Phone', 'Previous Price', 'Current Price', 'Change'],
      rows: @dashboard[:price_trends][:top_movers].map { |mover|
        [
          mover[:phone],
          number_to_currency(mover[:previous_price]),
          number_to_currency(mover[:current_price]),
          content_tag(:span,
            "#{mover[:change_percent]}%",
            class: mover[:change_percent] < 0 ? 'text-accent-green' : 'text-accent-red'
          )
        ]
      } %>
  </section>

  <!-- Regional Alerts -->
  <% if @dashboard[:regional_gaps][:uae_violators].any? %>
  <section class="bg-accent-red/10 border border-accent-red rounded p-6">
    <h2 class="font-display text-xl font-bold text-accent-red mb-4">
      ⚠️ Critical Price Violations (30%+ below UAE benchmark)
    </h2>
    <ul class="space-y-2">
      <% @dashboard[:regional_gaps][:uae_violators].each do |violation| %>
        <li class="font-body text-sm">
          <strong><%= violation[:phone] %></strong> in
          <%= violation[:country] %> (<%= violation[:channel] %>):
          <%= violation[:discount_percent] %>% below benchmark
        </li>
      <% end %>
    </ul>
  </section>
  <% end %>
</div>
```

---

### 3. Stimulus Controller: Chart

**File**: `app/javascript/controllers/chart_controller.js`

```javascript
import { Controller } from '@hotwired/stimulus';
import Chart from 'chart.js/auto';

export default class extends Controller {
  static values = {
    type: { type: String, default: 'line' },
    data: Array,
    options: Object
  };

  connect() {
    this.renderChart();
  }

  renderChart() {
    const ctx = this.element.getContext('2d');

    // Chart.js configuration for Financial Times style
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'bottom',
          labels: {
            font: {
              family: "'Source Sans Pro', sans-serif",
              size: 12
            },
            color: '#5A5A5A'
          }
        },
        tooltip: {
          backgroundColor: 'rgba(26, 26, 26, 0.9)',
          titleFont: {
            family: "'Playfair Display', serif",
            size: 14
          },
          bodyFont: {
            family: "'Source Sans Pro', sans-serif",
            size: 12
          },
          padding: 12,
          cornerRadius: 4
        }
      },
      scales: {
        x: {
          grid: {
            display: false
          },
          ticks: {
            font: {
              family: "'IBM Plex Mono', monospace",
              size: 11
            },
            color: '#5A5A5A'
          }
        },
        y: {
          grid: {
            color: '#E0DCC8',
            drawBorder: false
          },
          ticks: {
            font: {
              family: "'IBM Plex Mono', monospace",
              size: 11
            },
            color: '#5A5A5A'
          }
        }
      }
    };

    this.chart = new Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: { ...defaultOptions, ...this.optionsValue }
    });
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
}
```

---

## Database Queries

### Optimized Queries with Eager Loading

```ruby
# DashboardService - Avoid N+1 queries
def self.home_stats(time_range_days: 30)
  # Eager load associations
  prices_with_associations = Price
    .where('date >= ?', time_range_days.days.ago.to_date)
    .includes(:phone, :channel)  # Prevents N+1

  # Calculate stats
  {
    overview: overview_stats,
    price_trends: calculate_price_trends(prices_with_associations),
    regional_gaps: analyze_regional_gaps(prices_with_associations)
  }
end

# ChannelStrategyService - Single query with joins
def self.analyze(phone_id, country_id: nil)
  # Single query with JOINs
  prices = Price
    .where(phone_id:)
    .joins(channel: :country)
    .select('prices.*, channels.name as channel_name, channels.channel_type, countries.name as country_name')
    .then { |scope| country_id ? scope.where(countries: { id: country_id }) : scope }

  # Build response from single query result
  # ...
end

# CompetitionService - Aggregation query
def self.calculate_brand_share(country_id: nil)
  query = Phone.joins(:prices).group(:brand)

  if country_id
    query = query.joins(prices: { channel: :country })
              .where(countries: { id: country_id })
  end

  # Single aggregation query
  query.count
end
```

---

## Routing Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # API Routes (existing)
  namespace :api do
    namespace :v1 do
      # ... existing routes
    end
  end

  # Dashboard Routes (new)
  scope :dashboard do
    get '/', to: 'dashboard#home', as: :dashboard_home
    get '/channel_strategy', to: 'dashboard#channel_strategy', as: :dashboard_channel
    get '/competition', to: 'dashboard#competition', as: :dashboard_competition
    get '/promotions', to: 'dashboard#promotions', as: :dashboard_promotions
    get '/regional_prices', to: 'dashboard#regional_prices', as: :dashboard_regional
    get '/search', to: 'dashboard#search', as: :dashboard_search
  end

  # Root path
  root to: redirect('/dashboard')
end
```

---

## Implementation Checklist

### Phase 1: Configuration ✅
- [ ] Remove `config.api_only = true` from `config/application.rb`
- [ ] Add gems to Gemfile:
  - [ ] `gem 'turbo-rails'`
  - [ ] `gem 'stimulus-rails'`
  - [ ] `gem 'tailwindcss-rails'`
- [ ] Run `bundle install`
- [ ] Install Chart.js via importmap: `bin/importmap pin chart.js`

### Phase 2: Design System ✅
- [ ] Configure Tailwind with custom colors/fonts
- [ ] Create `app/views/layouts/application.html.erb`
- [ ] Create partials: `_header.html.erb`, `_navigation.html.erb`, `_footer.html.erb`
- [ ] Create shared components: `_kpi_card.html.erb`, `_data_table.html.erb`

### Phase 3: Controllers & Services ✅
- [ ] `DashboardController` with 5 actions
- [ ] `DashboardService` - home_stats method
- [ ] `ChannelStrategyService` - analyze method
- [ ] `CompetitionService` - market_analysis method
- [ ] `PromotionService` - active_promotions method
- [ ] `RegionalPriceService` - benchmark_analysis method

### Phase 4: Views ✅
- [ ] `app/views/dashboard/home.html.erb`
- [ ] `app/views/dashboard/channel_strategy.html.erb`
- [ ] `app/views/dashboard/competition.html.erb`
- [ ] `app/views/dashboard/promotions.html.erb`
- [ ] `app/views/dashboard/regional_prices.html.erb`
- [ ] `app/views/dashboard/search.html.erb`

### Phase 5: JavaScript ✅
- [ ] Stimulus controller: `search_controller.js`
- [ ] Stimulus controller: `chart_controller.js`
- [ ] Stimulus controller: `filter_controller.js`
- [ ] Chart.js configurations for each chart type

### Phase 6: Testing ✅
- [ ] Controller tests
- [ ] Service tests
- [ ] System tests (Turbo Frame interactions)
- [ ] Lighthouse performance audit

---

## Performance Considerations

### Caching Strategy

```ruby
# Fragment caching for KPI cards
<% cache 'dashboard_overview', expires_in: 12.hours do %>
  <%= render 'shared/kpi_card', ... %>
<% end %>

# Low-level caching for expensive calculations
def self.market_share(country_id: nil)
  Rails.cache.fetch("market_share_#{country_id}", expires_in: 1.hour) do
    calculate_brand_share(country_id)
  end
end

# HTTP caching for API responses
def home
  @dashboard = DashboardService.home_stats
  fresh_when(@dashboard)
end
```

### Query Optimization

- Use `includes()` to prevent N+1 queries
- Add database indexes on frequently queried columns
- Limit Chart.js data points to max 1000
- Lazy load charts with Stimulus lifecycle callbacks

---

## Accessibility

### ARIA Labels

```erb
<!-- Navigation -->
<nav aria-label="Dashboard navigation">
  <ul class="nav-links">
    <li>
      <%= link_to 'Home', dashboard_path,
          aria: { current: current_page?(dashboard_path) ? 'page' : nil } %>
    </li>
  </ul>
</nav>

<!-- Data Tables -->
<table class="data-table" role="table">
  <caption>Price trends by country</caption>
  <thead>
    <tr role="row">
      <th scope="col">Country</th>
      <th scope="col">Average Price</th>
    </tr>
  </thead>
  <tbody>
    <%= render @countries %>
  </tbody>
</table>
```

### Keyboard Navigation

- All interactive elements must be keyboard accessible
- Tab order follows visual layout
- Focus indicators visible (outline: 2px solid FT Blue)
- Skip to main content link

---

## Testing Strategy

### Controller Tests

```ruby
# test/controllers/dashboard_controller_test.rb
class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get dashboard_home_url
    assert_response :success
    assert_select 'h1', 'Dashboard Overview'
  end

  test "should display KPI cards" do
    get dashboard_home_url
    assert_select '.kpi-card', 4
  end
end
```

### Service Tests

```ruby
# test/services/dashboard_service_test.rb
class DashboardServiceTest < ActiveSupport::TestCase
  test "home_stats returns overview" do
    stats = DashboardService.home_stats

    assert stats[:overview].present?
    assert stats[:overview][:total_phones] > 0
  end

  test "price_trends returns country data" do
    stats = DashboardService.home_stats

    assert stats[:price_trends][:by_country].is_a?(Array)
  end
end
```

---

## Success Metrics

### Functional Requirements
- [ ] All 5 pages accessible and rendering correctly
- [ ] KPI cards display real data from database
- [ ] Charts render with accurate data
- [ ] Semantic search returns relevant results
- [ ] Turbo Frame transitions < 100ms

### Performance Requirements
- [ ] Page load time < 2s (Lighthouse Performance > 90)
- [ ] Chart render time < 500ms
- [ ] Database queries < 100ms (with indexes)
- [ ] No N+1 queries (verified with Bullet gem)

### Design Requirements
- [ ] Playfair Display font on all headings
- [ ] FT Blue (#1E50A2) used for accents
- [ ] Consistent spacing (padding: 1.5rem)
- [ ] Responsive layout (mobile, tablet, desktop)
- [ ] Color contrast ratio > 4.5:1

---

## Dependencies

### Ruby Gems
```ruby
gem 'turbo-rails', '~> 7.3'
gem 'stimulus-rails', '~> 3.2'
gem 'tailwindcss-rails', '~> 2.0'
```

### JavaScript Libraries
```javascript
// config/importmap.rb
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
```

### External Services
- **BGE-M3 Server**: `http://127.0.0.1:8001` (Semantic search embeddings)
- **PostgreSQL**: Existing database with 3,245 phones, 1,878 prices

---

## Security Considerations

- No user authentication in Phase 3 (Phase 4 scope)
- SQL injection prevention (use parameterized queries)
- XSS prevention (Rails auto-escaping in ERB)
- CSRF protection (Turbo Rails includes CSRF tokens)
- Rate limiting (consider Rack::Attack for production)

---

## Next Steps

1. **Implementation**: Run `/pdca do rails-dashboard-ui`
2. **Development**: Follow implementation order from checklist
3. **Testing**: Run `/pdca analyze rails-dashboard-ui` after implementation

---

**Version**: 1.0
**Last Updated**: 2026-02-11
**Status**: ✅ Ready for Implementation
