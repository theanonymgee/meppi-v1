# frozen_string_literal: true

# Error handling concern for API controllers
# Provides consistent error responses across all controllers
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Rescue from common exceptions
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ArgumentError, with: :bad_request
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from StandardError, with: :internal_error
  end

  private

  # Handle 404 Not Found errors
  def not_found(exception)
    # Extract model name from exception message
    model_name = exception.model.to_s rescue 'Resource'

    render json: {
      error: "#{model_name} not found",
      message: exception.message
    }, status: :not_found
  end

  # Handle 400 Bad Request errors
  def bad_request(exception)
    render json: {
      error: 'Invalid request',
      message: exception.message
    }, status: :bad_request
  end

  # Handle 500 Internal Server Error
  def internal_error(exception)
    # Log the full error for debugging
    Rails.logger.error "Unexpected error: #{exception.class.name}"
    Rails.logger.error exception.message
    Rails.logger.error exception.backtrace.join("\n")

    # Return user-friendly message
    render json: {
      error: 'An unexpected error occurred',
      message: 'Please try again later or contact support if the problem persists'
    }, status: :internal_server_error
  end
end
