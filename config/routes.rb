# frozen_string_literal: true

Rails.application.routes.draw do
  # Root path - Dashboard
  root 'dashboard#index'

  # Trade CRUD API resources
  resources :trades, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # Dashboard feature routes
  get '/dashboard', to: 'dashboard#home'

  # Feature routes
  resources :competition, only: [:index, :show]
  resources :promotion, only: [:index, :show]
  resources :regional_price, only: [:index, :show]
  get '/channel-comparison', to: 'channel_comparison#index'

  # MEPI special routes
  get '/benchmark', to: 'trades#benchmark'

  # API endpoints for semantic search
  # Using v1 API as single source of truth for semantic search
  namespace :api do
    namespace :v1 do
      # Semantic search using natural language query
      post '/semantic_search', to: 'v1/semantic_search#create'

      # Find similar phones by ID
      get '/semantic_search/:id/similar', to: 'v1/semantic_search#similar'

      # Hotwire Native navigation endpoint
      get '/navigation', to: 'native_bridge#navigation'
    end

    # Legacy RAG search endpoint (deprecated - use /api/v1/semantic_search)
    post '/rag/search', to: 'v1/semantic_search#create'
  end

  # Health check endpoint
  get '/health', to: 'application#health'
end
