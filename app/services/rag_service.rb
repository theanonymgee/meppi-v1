# frozen_string_literal: true

# RAG (Retrieval-Augmented Generation) 검색 서비스
class RagService
  class RagError < StandardError; end

  # 벡터 유사도 검색
  # @param trade [ApplicationRecord] 거래 레코드
  # @param query_text [String] 검색 쿼리 텍스트
  # @param limit [Integer] 반환할 결과 개수 (default: 5)
  # @return [Array<Chunk>] 유사한 청크 배열
  def self.similar_chunks(trade:, query_text:, limit: 5)
    # 쿼리 텍스트 임베딩
    embedding = EmbeddingService.embed(query_text)

    # pgvector로 유사도 검색
    Chunk.similar(embedding: embedding, limit: limit)
  end

  # 새로운 청크 생성 및 임베딩
  # @param trade [ApplicationRecord] 거래 레코드
  # @param content [String] 청크 내용
  # @return [Chunk] 생성된 청크
  def self.create_chunk(trade:, content:)
    # 내용을 텍스트 청크로 분할 (선택 사항)
    chunks = split_content(content)

    # 각 청크 임베딩
    embeddings = EmbeddingService.embed_batch(chunks.map { |c| c[:text] })

    # DB에 청크 저장
    chunks.each_with_index do |chunk, index|
      trade.chunks.create!(
        content: chunk[:text],
        embedding: embeddings[index],
        tokens: chunk[:tokens]
      )
    end
  end

  # 텍스트 청크 분할
  # @param content [String] 전체 내용
  # @return [Array<Hash>] 청크 배열 {text:, tokens:}
  def self.split_content(content)
    # 간단한 분할: 문장 단위 또는 고정 토큰 수
    sentences = content.split(/(?<=[.!?])\s+(?=[A-Z])/)

    sentences.map do |sentence|
      {
        text: sentence.strip,
        tokens: sentence.length # 대략적 토큰 수 추정
      }
    end
  end
end
