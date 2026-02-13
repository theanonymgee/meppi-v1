# frozen_string_literal: true

# BGE-M3 Embedding Client
# HTTP client for local BGE-M3 embedding server
class BgeM3Client
  class Error < StandardError; end

  def initialize(base_url: nil, timeout: nil)
    @base_url = base_url || ENV.fetch('BGE_M3_SERVER_URL', 'http://127.0.0.1:8001')
    @timeout = timeout || ENV.fetch('BGE_M3_TIMEOUT', '30').to_i
  end

  # 단일 텍스트 임베딩 생성
  # @param text [String] 임베딩을 생성할 텍스트
  # @return [Array<Float>] 임베딩 벡터 (1024 차원)
  def generate(text)
    raise ArgumentError, 'Text cannot be empty' if text.blank?
    raise ArgumentError, 'Text must be a String' unless text.is_a?(String)

    response = connection.post('/embeddings') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { text: text }.to_json
    end

    handle_response(response)
  end

  # 배치 텍스트 임베딩 생성
  # @param texts [Array<String>] 임베딩을 생성할 텍스트 배열
  # @return [Array<Array<Float>>] 임베딩 벡터 배열
  def generate_batch(texts)
    raise ArgumentError, 'Texts cannot be empty' if texts.blank?
    raise ArgumentError, 'Texts must be an Array' unless texts.is_a?(Array)

    response = connection.post('/embeddings/batch') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { texts: texts }.to_json
    end

    handle_batch_response(response)
  end

  # 서버 헬스 체크
  # @return [Boolean] 서버가 실행 중인지 여부
  def health_check
    response = connection.get('/health')

    response.status == 200
  rescue StandardError
    false
  end

  private

  def connection
    @connection ||= Faraday.new(@base_url) do |conn|
      conn.request :json
      conn.adapter Faraday.default_adapter
      conn.options.timeout = @timeout
      conn.options.open_timeout = 5
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      data = JSON.parse(response.body)
      data['embedding']
    when 400
      raise Error, "Bad Request: #{response.body}"
    when 503
      raise Error, 'Service Unavailable: Model not loaded'
    when 500..599
      raise Error, "Server error: #{response.body}"
    else
      raise Error, "Unexpected response: #{response.status}"
    end
  rescue JSON::ParserError => e
    raise Error, "Invalid JSON response: #{e.message}"
  end

  def handle_batch_response(response)
    case response.status
    when 200..299
      data = JSON.parse(response.body)
      data.map { |item| item['embedding'] }
    when 400
      raise Error, "Bad Request: #{response.body}"
    when 503
      raise Error, 'Service Unavailable: Model not loaded'
    when 500..599
      raise Error, "Server error: #{response.body}"
    else
      raise Error, "Unexpected response: #{response.status}"
    end
  rescue JSON::ParserError => e
    raise Error, "Invalid JSON response: #{e.message}"
  end
end
