# frozen_string_literal: true

# Competition Controller - Phone comparison and market analysis
# Single Responsibility: Handle competition-related requests
class CompetitionController < ApplicationController
  before_action :set_countries

  # Market analysis dashboard
  def index
    country_id = params[:country_id]

    @market_analysis = CompetitionService.market_analysis(country_id: country_id)
    @countries = Country.active.by_priority
  rescue StandardError => e
    handle_error(e, 'Competition analysis')
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
    handle_error(e, 'Phone comparison')
  end

  private

  def set_countries
    @countries = Country.active.by_priority
  end

  def handle_error(exception, context)
    Rails.logger.error("#{context}: #{exception.message}")
    flash[:alert] = "#{context.humanize} failed: #{exception.message}"
    redirect_to competition_list_path
  end
end
