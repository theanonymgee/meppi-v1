# frozen_string_literal: true

namespace :embeddings do
  desc 'Generate embeddings for all phones without embeddings'
  task generate_all: :environment do
    puts "=== 임베딩 생성 시작 ==="
    puts "총 폰 수: #{Phone.count}"
    puts "이미 임베딩 있는 폰: #{Phone.where.not(embedding: nil).count}"
    puts "임베딩 필요한 폰: #{Phone.where(embedding: nil).count}"
    puts ''

    # Z.AI API Key 확인
    if ENV['ZAI_API_KEY']&.include?('your_zai_api_key_here')
      puts '⚠️  경고: Z.AI API Key가 설정되지 않았습니다.'
      puts '   .env 파일에 ZAI_API_KEY를 설정해주세요.'
      puts '   임베딩 생성을 건너뜁니다.'
      next
    end

    # 배치로 처리
    batch_size = EmbeddingConstants::EMBEDDING_BATCH_SIZE
    total_phones = Phone.where(embedding: nil).count
    processed = 0
    failed = 0

    Phone.where(embedding: nil).find_each(batch_size: batch_size) do |phone|
      begin
        embedding = EmbeddingService.generate_phone_embedding(phone)
        phone.update(embedding: embedding)
        processed += 1

        # 진행률 표시
        if processed % 10 == 0
          puts "진행률: #{processed}/#{total_phones} (#{(processed.to_f / total_phones * 100).round(1)}%)"
        end
      rescue EmbeddingService::EmbeddingError => e
        failed += 1
        Rails.logger.error "임베딩 생성 실패 (Phone ##{phone.id}): #{e.message}"
        puts "⚠️  Phone ##{phone.id} 실패: #{e.message}"
      end
    end

    puts ''
    puts "=== 임베딩 생성 완료 ==="
    puts "성공: #{processed}"
    puts "실패: #{failed}"
    puts "총 임베딩: #{Phone.where.not(embedding: nil).count}/#{Phone.count}"
  end

  desc 'Generate embedding for a specific phone'
  task :generate_one, [:phone_id] => :environment do |_t, args|
    phone_id = args[:phone_id]
    phone = Phone.find(phone_id)

    puts "Phone ##{phone.id}: #{phone.full_name}"
    puts "브랜드: #{phone.brand}"
    puts "모델: #{phone.model}"

    if phone.embedding.present?
      puts '이미 임베딩이 존재합니다.'
      next
    end

    embedding = EmbeddingService.generate_phone_embedding(phone)
    phone.update(embedding: embedding)

    puts "임베딩 생성 완료! (차원: #{embedding.length})"
  end

  desc 'Show embedding statistics'
  task stats: :environment do
    total = Phone.count
    with_embedding = Phone.where.not(embedding: nil).count
    without_embedding = Phone.where(embedding: nil).count

    puts '=== 임베딩 통계 ==='
    puts "총 폰: #{total}"
    puts "임베딩 있음: #{with_embedding} (#{(with_embedding.to_f / total * 100).round(1)}%)"
    puts "임베딩 없음: #{without_embedding} (#{(without_embedding.to_f / total * 100).round(1)}%)"
  end

  desc 'Remove all embeddings (for testing)'
  task :clear_all => :environment do
    puts '⚠️  모든 임베딩을 삭제합니다...'
    Phone.update_all(embedding: nil)
    Price.update_all(embedding: nil)
    puts '완료!'
  end

  desc 'Import phone embeddings from CSV file'
  task import_from_csv: :environment do
    csv_file = ENV.fetch('CSV_FILE', '/tmp/phones_embeddings.csv')

    unless File.exist?(csv_file)
      puts "ERROR: CSV file not found: #{csv_file}"
      exit 1
    end

    puts "=== Importing Embeddings from CSV ==="
    puts "CSV File: #{csv_file}"
    puts

    require 'csv'
    require 'pg'

    imported_count = 0
    skipped_count = 0
    error_count = 0

    # Get database connection
    conn = ActiveRecord::Base.connection.raw_connection

    CSV.foreach(csv_file, headers: true) do |row|
      begin
        phone_id = row['phone_id']
        brand = row['brand']
        model = row['model']
        embedding_str = row['embedding']

        # Check if phone exists
        phone_exists = conn.exec_params(
          'SELECT id FROM phones WHERE id = $1',
          [phone_id]
        )

        if phone_exists.ntuples == 0
          skipped_count += 1
          puts "SKIP: Phone #{phone_id} not found (#{brand} #{model})"
          next
        end

        # Parse embedding array string: "[0.1, -0.2, ...]"
        embedding_array = JSON.parse(embedding_str)

        # Validate dimensions
        unless embedding_array.is_a?(Array) && embedding_array.length == 1024
          error_count += 1
          puts "ERROR: Invalid embedding for phone #{phone_id}: dimensions=#{embedding_array&.length}"
          next
        end

        # Update embedding using raw SQL with pgvector format
        # pgvector format: "[0.1, -0.2, 0.3, ...]"
        vector_str = embedding_array.inspect
        conn.exec_params(
          'UPDATE phones SET embedding = $1::vector WHERE id = $2',
          [vector_str, phone_id]
        )

        imported_count += 1

        if imported_count % 500 == 0
          puts "Progress: #{imported_count} phones updated"
        end

      rescue => e
        error_count += 1
        puts "ERROR: Failed to process row: #{e.message}"
        puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
      end
    end

    puts
    puts "=== Import Complete ==="
    puts "Imported: #{imported_count}"
    puts "Skipped: #{skipped_count}"
    puts "Errors: #{error_count}"
    puts

    # Verify
    total_with_embeddings = conn.exec('SELECT COUNT(*) FROM phones WHERE embedding IS NOT NULL').getvalue(0, 0).to_i
    puts "Verification: #{total_with_embeddings} phones have embeddings in database"
  end

  desc 'Migrate ChromaDB to PostgreSQL (export + import)'
  task migrate_chromadb: :environment do
    puts "Step 1: Exporting ChromaDB to CSV..."
    chromadb_script = Rails.root.join('lib', 'scripts', 'migrate_chromadb_to_pgvector.py')

    unless File.exist?(chromadb_script)
      puts "ERROR: Migration script not found: #{chromadb_script}"
      exit 1
    end

    # Run Python export script
    system("python3", chromadb_script.to_s)

    if $?.success?
      puts "ChromaDB export completed successfully"
    else
      puts "ERROR: ChromaDB export failed"
      exit 1
    end
  end
end
