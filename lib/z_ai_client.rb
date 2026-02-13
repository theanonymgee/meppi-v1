# frozen_string_literal: true

# Z.AI HTTP Client
# Z.AI 임베딩 및 LLM API 연동을 위한 클라이언트 클래스
# API Key 직접 인증 방식 (v4+)
class ZAiClient
  class Error < StandardError; end

  def initialize(api_key, base_url: nil)
    @api_key = api_key
    # Z.AI/智谱AI 공식 API Base URL
    @base_url = base_url || ENV.fetch('ZAI_API_BASE_URL', 'https://open.bigmodel.cn/api/paas/v4')
  end

  # 임베딩 생성
  # @param model [String] 임베딩 모델명 (예: "embedding-2")
  # @param input [String, Array<String>] 임베딩을 생성할 텍스트
  # @return [Hash] API 응답 (data, model, usage 등)
  def create_embedding(model:, input:)
    response = connection.post('/embeddings') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.body = {
        model: model,
        input: input
      }.to_json
    end

    handle_response(response)
  end

  # 채팅 완성 생성 (LLM)
  # @param messages [Array<Hash>] 메시지 배열 [{role: "system", content: "..."}]
  # @param model [String] LLM 모델명 (예: "glm-4.7")
  # @param options [Hash] 추가 옵션 (temperature, max_tokens 등)
  # @return [Hash] API 응답
  def create_chat_completion(messages:, model:, **options)
    response = connection.post('/chat/completions') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.body = {
        model: model,
        messages: messages,
        **options
      }.to_json
    end

    handle_response(response)
  end

  private

  def connection
    @connection ||= Faraday.new(@base_url) do |conn|
      conn.request :json
      conn.request :retry # retry middleware
      conn.adapter Faraday.default_adapter
      conn.options.timeout = ENV.fetch('ZAI_TIMEOUT', '30').to_i
      conn.options.open_timeout = 5
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400
      raise Error, "Bad Request: #{response.body}"
    when 401
      raise Error, 'Unauthorized: Invalid API key'
    when 429
      raise Error, 'Rate limit exceeded'
    when 500..599
      raise Error, "Z.AI server error: #{response.body}"
    else
      raise Error, "Unexpected response: #{response.status}"
    end
  end
end
