# frozen_string_literal: true

# Application Helper module
# Provides helper methods for views across the application
module ApplicationHelper
  # Dashboard path helpers
  # These methods generate URLs for dashboard sections

  def dashboard_channel_path(phone_id = nil)
    if phone_id.present?
      '/dashboard/channel_strategy?phone_id=%<phone_id%'
    else
      '/dashboard/channel_strategy'
    end
  end

  def dashboard_competition_path(country_id = nil)
    if country_id.present?
      '/dashboard/competition?country_id=%<country_id>%'
    else
      '/dashboard/competition'
    end
  end

  def dashboard_promotions_path(country_id = nil)
    if country_id.present?
      '/dashboard/promotions?country_id=%<country_id>%'
    else
      '/dashboard/promotions'
    end
  end

  def dashboard_regional_prices_path(phone_id = nil)
    if phone_id.present?
      '/dashboard/regional_prices?phone_id=%<phone_id>%'
    else
      '/dashboard/regional_prices'
    end
  end

  def dashboard_search_path
    '/dashboard/search'
  end
end
