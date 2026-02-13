# meppi-rails Dashboard

Mobile price intelligence dashboard combining MEPI and GSM data with semantic search and Hotwire Native support.

## Overview

meppi-rails provides a unified dashboard for analyzing mobile phone prices across Middle East markets. Features include:

- **Channel Price Comparison** - Compare prices across retail channels (telco, online, hypermarket)
- **Competition Comparison** - Side-by-side device comparison with specs and pricing
- **Promotion Timeline** - Track brand promotions, discounts, and special offers
- **Regional Price Comparison** - Cross-country price analysis vs UAE benchmark

## Tech Stack

- **Ruby:** 3.2.3
- **Framework:** Ruby on Rails 7.1
- **Database:** PostgreSQL with pgvector extension
- **Frontend:** Turbo-Rails, Stimulus, TailwindCSS
- **Testing:** RSpec
- **Native:** Hotwire Native (iOS/Android)

## Architecture

Controllers, Services, and Models following Rails patterns:
- Single Responsibility per class
- Vibe Coding 6 principles compliance
- TDD methodology
- Semantic search via OpenAI embeddings

## Getting Started

Prerequisites:
- Ruby 3.2.3+
- PostgreSQL 14+ with pgvector extension
- Node.js 18+ (for asset compilation)

Installation:
\`\`\`bash
bundle install
npm install
rails db:create
rails db:migrate
\`\`\`

## Running

Development:
\`\`\`bash
rails server
\`\`\`

Tests:
\`\`\`bash
bundle exec rspec
\`\`\`

API Endpoint: GET /api/v1/navigation
