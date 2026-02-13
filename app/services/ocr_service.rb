# frozen_string_literal: true

# PaddleOCR API 서비스
class OcrService
  # API 서버 설정
  PADDLEOCR_URL = ENV.fetch('PADDLEOCR_URL', 'http://localhost:8003')
  PADDLEOCR_TIMEOUT = Integer(ENV.fetch('PADDLEOCR_TIMEOUT', '30'))

  class OcrError < StandardError; end

  # 이미지 텍스트 추출
  # @param image_path [String] 이미지 파일 경로 또는 URL
  # @return [Hash] 추출된 텍스트와 신뢰도 정보
  def self.extract_text(image_path)
    raise OcrError, "Invalid image path: #{image_path}" unless image_path.present?

    # 이미지 파일인지 URL인지 확인
    data = if image_path.start_with?('http')
             { url: image_path }
           else
             raise OcrError, "File not found: #{image_path}" unless File.exist?(image_path)
             { file: File.open(image_path, 'rb') }
           end

    response = conn.post('/ocr') do |req|
      req.headers['Content-Type'] = 'multipart/form-data'
      req.body = data
    end

    handle_response(response, 'OCR')
  end

  # 배치 이미지 처리
  # @param image_paths [Array<String>] 이미지 경로 또는 URL 배열
  # @return [Array<Hash>] 추출된 텍스트 배열
  def self.extract_batch(image_paths)
    raise OcrError, "Image paths cannot be empty" if image_paths.empty?

    responses = image_paths.map do |path|
      raise OcrError, "Invalid image path" unless path.present?

      if path.start_with?('http')
        { url: path }
      else
        raise OcrError, "File not found: #{path}" unless File.exist?(path)
        { file: File.open(path, 'rb') }
      end
    end

    response = conn.post('/ocr_batch') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { images: responses }.to_json
    end

    handle_response(response, 'batch OCR')
  end

  private

  # HTTP 연결 관리
  def self.conn
    @conn ||= Faraday.new(url: PADDLEOCR_URL) do |f|
      f.options.timeout = PADDLEOCR_TIMEOUT
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
      raise OcrError, "Invalid request: #{response.body}"
    when 500
      raise OcrError, "OCR server error: #{response.body}"
    else
      raise OcrError, "Unexpected response: #{response.status} - #{response.body}"
    end
  rescue JSON::ParserError => e
    raise OcrError, "Failed to parse OCR response: #{e.message}"
  end
end
