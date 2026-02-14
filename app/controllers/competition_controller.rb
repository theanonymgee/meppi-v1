# frozen_string_literal: true

# Competition Controller - Phone comparison and market analysis
# Single Responsibility: Handle competition-related requests
class CompetitionController < ApplicationController
  before_action :set_countries

  # Comparison limits
  COMPARISON_MIN_PHONES = 2
  COMPARISON_MAX_PHONES = 4

  # Market analysis dashboard
  def index
    country_id = params[:country_id]

    @market_analysis = CompetitionService.market_analysis(country_id: country_id)
    @countries = Country.active.by_priority
  rescue StandardError => e
    Rails.logger.error("Competition analysis: #{e.message}")
    @market_analysis = default_market_analysis
    @countries = Country.active.by_priority
  end

  # Phone comparison view
  def compare
    phone_ids = params[:phone_ids]&.split(',')&.map(&:to_i)&.reject(&:zero?)
    @phones = Phone.select(:id, :brand, :model).order(:brand, :model).limit(100)

    if phone_ids.present? && phone_ids.length >= COMPARISON_MIN_PHONES && phone_ids.length <= COMPARISON_MAX_PHONES
      @comparison_data = CompetitionService.compare_phones(phone_ids)
      @insights = CompetitionService.generate_comparison_insights(@comparison_data)
      @selected_phones = Phone.where(id: phone_ids)
    end
  rescue StandardError => e
    Rails.logger.error("Phone comparison: #{e.message}")
    @comparison_data = []
    @insights = {}
    @selected_phones = []
  end

  private

  def set_countries
    @countries = Country.active.by_priority
  end

  def default_market_analysis
    {
      market_share: {},
      top_models: [],
      new_entries: []
    }
  end
end
