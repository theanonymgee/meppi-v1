# frozen_string_literal: true

class Api::V1::StatsController < ApplicationController
  include ErrorHandler

  # GET /api/v1/stats/summary
  def summary
    stats = StatsService.summary
    render json: stats
  end
end
