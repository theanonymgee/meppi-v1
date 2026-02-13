# frozen_string_literal: true

class Api::V1::PhonesController < ApplicationController
  include ErrorHandler

  before_action :set_phone, only: %i[show prices]

  # GET /api/v1/phones
  def index
    phones = Phone.recent.limit(PaginationConstants::DEFAULT_PAGE_LIMIT)
    render json: phones
  end

  # GET /api/v1/phones/:id
  def show
    render json: @phone
  end

  # GET /api/v1/phones/:id/prices
  def prices
    prices = @phone.prices.recent.includes(:channel)
    render json: prices
  end

  private

  def set_phone
    @phone = Phone.find(params[:id])
  end
end
