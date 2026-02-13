# frozen_string_literal: true

require_relative 'base_task'
require 'faraday'
require 'json'

# BGE-M3 Batch Embedder Task
# Vibe Coding: Single Responsibility, Error Handling, No Hardcoding
#
# This task connects to the local BGE-M3 server to generate embeddings for phone data

class BgeM3BatchEmbedder < BaseTask
  # BGE-M3 API configuration
  BGE_M3_API = ENV.fetch('BGE_M3_API_URL', 'http://127.0.0.1:8001')
  BATCH_ENDPOINT = '/embeddings/batch'
  TIMEOUT = ENV.fetch('BGE_M3_TIMEOUT', '60').to_i

  # Template constants
  BATCH_SIZE = 50  # Process 50 texts at a time
  EMBEDDING_DIM = 1024

  def initialize(api_url: nil, timeout: nil)
    @api_url = api_url || BGE_M3_API
    @timeout = timeout || TIMEOUT
  end

  # Generate embedding text for phone
  # @param phone [Hash] Phone record
  # @return [String] Text for embedding
  def phone_to_text(phone)
    # Vibe Coding: No hardcoded field names - extract from constants
    brand = phone[:brand] || ''
    model = phone[:model] || ''
    display_type = phone[:display_type] || ''
    storage = phone[:storage] || ''
    ram = phone[:ram] || ''
    camera = phone[:camera_specs] || ''

    # Combine: "Brand Model Storage DisplayType RAM Camera"
    # Remove any nil values and strip whitespace
    [brand, model, display_type, storage, ram, camera].map(&:to_s).compact.join(' ').strip
  end

  # Check BGE-M3 API health
  # @return [Boolean] true if service is available
  def check_api_health
    connection = Faraday.new(@api_url) do |conn|
      conn.options.timeout = 5
      conn.options.open_timeout = 5
    end

    response = connection.get('/health')
    response.status == 200
  rescue StandardError => e
      Rails.logger.error("BGE-M3 health check failed: #{e.message}")
      return false
    end

  # Generate embedding for single phone
  # @param text [String] Text to embed
  # @return [Hash] Embedding result or error
  def generate_embedding(text)
    begin
      response = connection.post(BATCH_ENDPOINT) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = { texts: [text] }.to_json
      end

      case response.status
      when 200..299
        data = JSON.parse(response.body)

        # Check for embeddings or error
        if data['error']
          return {
            success: false,
            error: data['error'],
            text: text
          }
        end

        if data['embeddings'] && data['embeddings'].any?
          return {
            success: true,
            embedding: data['embeddings'].first,
            text: text,
            dimensions: EMBEDDING_DIM
          }
        else
          return {
            success: false,
            error: 'No embeddings returned'
          }
        end
      when 503
        return {
            success: false,
            error: 'BGE-M3 service unavailable'
          }
      when 500..599
        error_msg = "Server error: #{response.status}"
        return {
          success: false,
          error: error_msg
          }
      else
        return {
          success: false,
          error: "Unexpected response: #{response.status}"
        }
    rescue Faraday::Error => e
      Rails.logger.error("BGE-M3 API connection failed: #{e.message}")
      return {
        success: false,
        error: "Failed to connect to BGE-M3 service: #{e.message}"
        }
    rescue StandardError => e
      Rails.logger.error("Embedding generation failed: #{e.message}")
      return {
        success: false,
        error: "Embedding failed: #{e.message}"
        }
    end

  # Process all phones from CSV file
  # @param csv_file [String] Path to exported CSV
  # @return [Hash] Processing result
  def process_csv(csv_file)
    total_phones = 0
    successful_count = 0
    failed_count = 0

    Rails.logger.info("Processing CSV: #{csv_file}")

    begin
      # Read CSV file
      CSV.foreach(csv_file, headers: true) do |row|
        total_phones += 1

        # Skip header row
        next if row['brand'].nil? && row['brand'].strip.empty?

        # Generate embedding text
        text = phone_to_text(row)
        Rails.logger.debug("Processing: #{text}")

        # Generate embedding
        result = generate_embedding(text)

        if result[:success]
          successful_count += 1

          # Store embedding for later PostgreSQL import
          # We'll store it as a JSON array string
          embedding_json = result[:embedding].to_json

          # Add to result
          result[:phone_id] = row['id']
          result[:embedding] = embedding_json
        else
          failed_count += 1

          # Log every 100 phones to show progress
          if total_phones % 100 == 0
            Rails.logger.info("Processed #{total_phones} phones...")
          end
        end
      rescue CSV::MalformedCSVError => e
        Rails.logger.error("CSV parsing failed: #{e.message}")
        return {
          success: false,
          error: "CSV file error: #{e.message}",
          total_phones: total_phones,
          successful_count: successful_count,
          failed_count: failed_count
        }
      end

    # Main execute method
    # @return [Hash] Task execution result
    def execute
      begin
        before_execute

        # Check if BGE-M3 API is available
        unless check_api_health
          return {
            success: false,
            error: 'BGE-M3 service is not available',
            csv_file: @csv_file || 'Not specified'
          }
        end

        # Process CSV file
        result = process_csv(@csv_file)

        after_execute(result)

        result
      rescue StandardError => e
        Rails.logger.error("Batch embedding failed: #{e.message}")
        on_error(e)
        raise "Batch embedding process failed: #{e.message}"
      end
end
