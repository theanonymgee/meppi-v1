# frozen_string_literal: true

# Base Task
# Abstract base class for all data import tasks
# Vibe Coding: Single Responsibility, Error Handling, Shared Code

class BaseTask
  # Abstract method to be implemented by subclasses
  # @return [Hash] Task execution result
  def execute
    raise NotImplementedError, 'Subclasses must implement execute method'
  end

  # Template method hook for before task execution
  # @return [void]
  def before_execute
    # Override in subclasses if needed
  end

  # Template method hook for after task execution
  # @return [Hash] Result to be merged with other tasks
  def after_execute(result)
    result
  end

  # Template method hook for error handling
  # @return [Hash] Error result
  def on_error(error)
    {
      success: false,
      error: error.class.name,
      message: error.message,
      backtrace: error.backtrace.first(5)
    }
  end

  # Execute task with proper error handling
  # @return [Hash] Execution result
  def run_safe
    begin
      before_execute
      result = execute
      after_execute(result)
      result
    rescue StandardError => e
      Rails.logger.error("Task error: #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
      on_error(e)
    end
  end
end
