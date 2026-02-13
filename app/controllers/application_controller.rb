# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Health check endpoint
  def health
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601
    }
  end
end
