# frozen_string_literal: true

# Dashboard Controller - Main web interface controller
# Handles all dashboard page rendering with proper error handling
# Vibe Coding: Single responsibility per action, proper error handling
class DashboardController < ApplicationController
  before_action :set_time_range, only: [:home]

  # GET /dashboard
  # Home dashboard with overview statistics
  def home
    @dashboard = DashboardService.home_stats(time_range_days: 30)
  rescue StandardError => e
    handle_error(e, 'Dashboard overview')
  end

  # GET /dashboard/channel_strategy
  # Channel price comparison and recommendations
  def channel_strategy
    phone_id = params[:phone_id]
    country_id = params[:country_id]

    if phone_id.present?
      @analysis = ChannelStrategyService.analyze(phone_id, country_id: country_id)
      @phone = Phone.find_by(id: phone_id)
    else
      # Show phone selection page
      @phones = Phone.select(:id, :brand, :model)
                     .order(:brand, :model)
                     .page(params[:page])
                     .per(20)
    end
  rescue StandardError => e
    handle_error(e, 'Channel strategy analysis')
  end

  # GET /dashboard/competition
  # Market analysis and competitive positioning
  def competition
    country_id = params[:country_id]

    @market_analysis = CompetitionService.market_analysis(country_id: country_id)
    @countries = Country.active.by_priority
  rescue StandardError => e
    handle_error(e, 'Competition analysis')
  end

  # GET /dashboard/promotions
  # Active promotions tracking
  def promotions
    country_id = params[:country_id]

    @promotions_data = PromotionService.active_promotions(country_id: country_id)
    @countries = Country.active.by_priority
  rescue StandardError => e
    handle_error(e, 'Promotions tracking')
  end

  # GET /dashboard/regional_prices
  # UAE benchmark monitoring and regional comparison
  def regional_prices
    phone_id = params[:phone_id]

    if phone_id.present?
      @benchmark_data = RegionalPriceService.benchmark_analysis(phone_id)
      @phone = Phone.find_by(id: phone_id)
    else
      # Show aggregate analysis
      @aggregate_data = RegionalPriceService.benchmark_analysis
    end

    @countries = Country.active.by_priority
    @phones = Phone.select(:id, :brand, :model)
                   .order(:brand, :model)
                   .page(params[:page])
                   .per(20)
  rescue StandardError => e
    handle_error(e, 'Regional price analysis')
  end

  # GET /dashboard/search
  # Semantic search interface
  def search
    # The search UI handles API calls via JavaScript
    # This just renders the search page
  rescue StandardError => e
    handle_error(e, 'Search interface')
  end

  private

  # Set time range from params or default
  def set_time_range
    @time_range_days = params[:period]&.to_i || 30
  end

  # Handle errors with user-friendly message
  # @param error [Exception] The error object
  # @param context [String] Error context for logging
  def handle_error(error, context)
    Rails.logger.error("Dashboard error in #{context}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if Rails.env.development?

    # Set error message for display
    @error = {
      context:,
      message: error.message,
      suggestion: generate_error_suggestion(error)
    }

    # Render error page or add flash
    flash.now[:alert] = "An error occurred while loading #{context.downcase}. Please try again."
  end

  # Generate user-friendly error suggestions
  # @param error [Exception] The error object
  # @return [String] Suggestion message
  def generate_error_suggestion(error)
    case error.class.name
    when 'ActiveRecord::RecordNotFound'
      'The requested record was not found. Please check your selection and try again.'
    when 'ActiveRecord::StatementInvalid', 'PG::Error'
      'A database error occurred. Please try again or contact support if the problem persists.'
    when 'ArgumentError', 'TypeError'
      'Invalid parameters provided. Please check your input and try again.'
    else
      'Please try again or contact support if the problem persists.'
    end
  end
end
