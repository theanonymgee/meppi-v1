# frozen_string_literal: true

Rails.application.routes.draw do
  # Root path - Dashboard
  root 'dashboard#home'

  # Trade CRUD API resources
  resources :trades, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # Dashboard feature routes
  get '/dashboard', to: 'dashboard#home', as: 'dashboard_home'
  get '/dashboard/search', to: 'dashboard#search', as: 'dashboard_search'
  get '/dashboard/channel', to: 'dashboard#channel_strategy', as: 'dashboard_channel'
  get '/dashboard/competition', to: 'dashboard#competition', as: 'dashboard_competition'
  get '/dashboard/promotions', to: 'dashboard#promotions', as: 'dashboard_promotions'
  get '/dashboard/regional_prices', to: 'dashboard#regional_prices', as: 'dashboard_regional_prices'

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
      post '/semantic_search', to: 'semantic_search#create'

      # Find similar phones by ID
      get '/semantic_search/:id/similar', to: 'semantic_search#similar'

      # Hotwire Native navigation endpoint
      get '/navigation', to: 'native_bridge#navigation'
    end

    # Legacy RAG search endpoint (deprecated - use /api/v1/semantic_search)
    post '/rag/search', to: 'v1/semantic_search#create'
  end

  # Health check endpoint
  get '/health', to: 'application#health'
end
