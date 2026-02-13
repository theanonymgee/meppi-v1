# frozen_string_literal: true

class Api::V1::CountriesController < ApplicationController
  include ErrorHandler

  before_action :set_country, only: %i[show channels]

  # GET /api/v1/countries
  def index
    countries = Country.active.by_priority
    render json: countries
  end

  # GET /api/v1/countries/:id
  def show
    render json: @country
  end

  # GET /api/v1/countries/:id/channels
  def channels
    channels = @country.channels.active
    render json: channels
  end

  private

  def set_country
    @country = Country.find(params[:id])
  end
end
