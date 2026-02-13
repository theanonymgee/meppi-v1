# frozen_string_literal: true

# Base API controller with common API functionality
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  rescue_from StandardError, with: :handle_error

  private

  def handle_error(error)
    render json: { error: error.message }, status: :internal_server_error
  end
end
