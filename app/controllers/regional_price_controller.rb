# frozen_string_literal: true

# RegionalPrice Controller - Cross-country price comparison
# Single Responsibility: Handle regional price analysis requests
class RegionalPriceController < ApplicationController
  before_action :set_base_country

  # Regional price comparison dashboard
  def index
    @base_country = Country.find_by(id: DashboardConstants::DEFAULT_BASE_COUNTRY_ID)
    @countries = Country.active.order(:priority)

    @regional_data = RegionalPriceService.compare_to_base(
      base_country_id: @base_country&.id,
      country_ids: params[:country_ids]&.reject(&:blank?)
    )
  rescue StandardError => e
    handle_error(e, 'Regional price comparison')
  end

  private

  def set_base_country
    @base_country = Country.find_by(id: DashboardConstants::DEFAULT_BASE_COUNTRY_ID)
  end

  def handle_error(exception, context)
    Rails.logger.error("#{context}: #{exception.message}")
    flash[:alert] = "#{context.humanize} failed: #{exception.message}"
    redirect_to regional_price_path
  end
end
