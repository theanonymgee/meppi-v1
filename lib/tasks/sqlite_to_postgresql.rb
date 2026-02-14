#!/usr/bin/env ruby
require 'sqlite3'
require 'pg'

class SqliteToPostgresql
  BATCH_SIZE = 1000

  def initialize(sqlite_path, pg_config)
    @sqlite_path = sqlite_path
    @pg_config = pg_config
    @sqlite_db = SQLite3::Database.new(sqlite_path)
    @pg_conn = PG.connect(pg_config)
    puts "Connected to SQLite: #{sqlite_path}"
    puts "Connected to PostgreSQL"
  end

  def get_tables
    sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"
    @sqlite_db.execute(sql).map { |row| row[0] }
  end

  def extract_create_table(table_name)
    sql = "SELECT sql FROM sqlite_master WHERE type='table' AND name=?;"
    result = @sqlite_db.execute(sql, table_name)
    result.first[0]
  end

  def convert_create_table(sqlite_sql)
    pg_sql = sqlite_sql.dup
    pg_sql.gsub!(/INTEGER PRIMARY KEY AUTOINCREMENT/i, 'BIGSERIAL PRIMARY KEY')
    pg_sql.gsub!(/\bINTEGER\b/, 'BIGINT')
    pg_sql.gsub!(/\bREAL\b/, 'DOUBLE PRECISION')
    pg_sql
  end

  def create_table(table_name)
    sqlite_sql = extract_create_table(table_name)
    pg_sql = convert_create_table(sqlite_sql)
    @pg_conn.exec("DROP TABLE IF EXISTS #{table_name} CASCADE")
    @pg_conn.exec(pg_sql)
    puts "  Created table: #{table_name}"
  end

  def get_columns(table_name)
    @sqlite_db.execute("PRAGMA table_info(#{table_name})").map { |row| row[1] }
  end

  def migrate_data(table_name)
    total = @sqlite_db.get_first_value("SELECT COUNT(*) FROM #{table_name}")
    return if total.zero?

    puts "  Migrating #{table_name}: #{total} records"
    columns = get_columns(table_name)
    placeholders = (1..columns.size).map { |i| "$#{i}" }.join(', ')

    offset = 0
    while offset < total
      batch = @sqlite_db.execute("SELECT * FROM #{table_name} LIMIT #{BATCH_SIZE} OFFSET #{offset}")
      batch.each do |row|
        @pg_conn.exec_params("INSERT INTO #{table_name} VALUES (#{placeholders})", row)
      end
      offset += BATCH_SIZE
      print "\r  Progress: #{[offset, total].min}/#{total}"
    end
    puts
  end

  def verify(table_name)
    sqlite_count = @sqlite_db.get_first_value("SELECT COUNT(*) FROM #{table_name}")
    pg_result = @pg_conn.exec("SELECT COUNT(*) FROM #{table_name}")
    pg_count = pg_result[0]['count'].to_i
    if sqlite_count == pg_count
      puts "  Verified #{table_name}: #{sqlite_count} records"
    else
      raise "Count mismatch: SQLite=#{sqlite_count}, PG=#{pg_count}"
    end
  end

  def close
    @sqlite_db.close if @sqlite_db
    @pg_conn.close if @pg_conn
  end
end
