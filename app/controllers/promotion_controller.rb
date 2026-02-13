# frozen_string_literal: true

# Promotion Controller - Brand promotion timeline tracking
# Single Responsibility: Handle promotion timeline requests
class PromotionController < ApplicationController
  before_action :set_channels

  # Promotion timeline dashboard
  def index
    country_id = params[:country_id]
    brand_id = params[:brand_id]

    @promotion_data = PromotionService.active_promotions(country_id: country_id)
    @discount_rankings = @promotion_data[:discount_ranking]
    @active_count = @promotion_data[:total_count]
    @avg_discount = @promotion_data[:avg_discount]

    @channels = Channel.active.by_priority
    @countries = Country.active.by_priority
    @brands = Phone.select(:brand).distinct.group(:brand).count
  rescue StandardError => e
    handle_error(e, 'Promotion timeline')
  end

  private

  def set_channels
    @channels = Channel.active.by_priority
  end

  def handle_error(exception, context)
    Rails.logger.error("#{context}: #{exception.message}")
    flash[:alert] = "#{context.humanize} failed: #{exception.message}"
    redirect_to promotion_path
  end
end
