# frozen_string_literal: true

# BGE-M3 Embedding API 서비스
class EmbeddingService
  # API 서버 설정
  BGE_EMBEDDING_URL = ENV.fetch('BGE_EMBEDDING_URL', 'http://localhost:8002')
  BGE_EMBEDDING_MODEL = ENV.fetch('BGE_EMBEDDING_MODEL', 'BAAI/bge-m3')

  # 타임아웃 설정
  EMBEDDING_TIMEOUT = 30

  class EmbeddingError < StandardError; end

  # 텍스트 임베딩
  # @param text [String] 임베딩할 텍스트
  # @return [Array<Float>] 1024차원 임베딩 벡터
  def self.embed(text)
    raise EmbeddingError, "Text cannot be empty" if text.blank?

    response = conn.post('/embed') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        model: BGE_EMBEDDING_MODEL,
        input: text
      }.to_json
    end

    handle_response(response, 'embedding')
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    raise EmbeddingError, "Connection error: #{e.message}"
  end

  # 배치 임베딩
  # @param texts [Array<String>] 임베딩할 텍스트 배열
  # @return [Array<Array<Float>>] 임베딩 벡터 배열
  def self.embed_batch(texts)
    raise EmbeddingError, "Texts array cannot be empty" if texts.empty?

    response = conn.post('/embed') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        model: BGE_EMBEDDING_MODEL,
        input: texts.map { |text| { text: } }
      }.to_json
    end

    handle_response(response, 'batch embedding')
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    raise EmbeddingError, "Connection error: #{e.message}"
  end

  private

  # HTTP 연결 관리
  def self.conn
    @conn ||= Faraday.new(url: BGE_EMBEDDING_URL) do |f|
      f.options.timeout = EMBEDDING_TIMEOUT
      f.adapter :net_http
    end
  end

  # API 응답 처리
  # @param response [Faraday::Response] HTTP 응답
  # @param context [String] 에러 컨텍스트
  def self.handle_response(response, context)
    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400
      raise EmbeddingError, "Invalid request: #{response.body}"
    when 500
      raise EmbeddingError, "Embedding server error: #{response.body}"
    else
      raise EmbeddingError, "Unexpected response: #{response.status} - #{response.body}"
    end
  rescue JSON::ParserError => e
    raise EmbeddingError, "Failed to parse embedding response: #{e.message}"
  end
end
