# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'db:migrate:from_sqlite' do
  let(:sqlite_db_path) { Rails.root.join('../meppi/meppi.db') }

  before do
    # Ensure SQLite database exists
    skip 'SQLite database not found' unless File.exist?(sqlite_db_path)
  end

  describe 'DRY-RUN mode' do
    it 'should report data counts without migrating' do
      # Record counts before DRY-RUN
      countries_before = Country.count
      channels_before = Channel.count
      prices_before = Price.count

      # Run DRY-RUN
      Rake::Task['db:migrate:from_sqlite'].invoke('SQLITE_DB_PATH' => sqlite_db_path.to_s, 'DRY_RUN' => 'true')

      # Reset the task so it can be invoked again
      Rake::Task['db:migrate:from_sqlite'].reenable

      # Verify counts haven't changed
      expect(Country.count).to eq(countries_before)
      expect(Channel.count).to eq(channels_before)
      expect(Price.count).to eq(prices_before)
    end
  end

  describe 'validation' do
    it 'should report validation results' do
      # Run validation task
      Rake::Task['db:migrate:validate'].invoke('SQLITE_DB_PATH' => sqlite_db_path.to_s)

      # Reset the task
      Rake::Task['db:migrate:validate'].reenable

      # The task should complete without errors
      expect { Rake::Task['db:migrate:validate'].invoke('SQLITE_DB_PATH' => sqlite_db_path.to_s) }.not_to raise_error
    end
  end

  describe 'Chunk model' do
    it 'should be valid with valid attributes' do
      phone = Phone.first
      skip 'No phones found' if phone.nil?

      chunk = Chunk.new(
        chunkable: phone,
        content: 'Test content',
        chunk_index: 0,
        metadata: { 'test' => 'data' }
      )

      expect(chunk).to be_valid
    end

    it 'should require content' do
      chunk = Chunk.new(content: nil)
      expect(chunk).not_to be_valid
      expect(chunk.errors[:content]).to be_present
    end

    it 'should require chunk_index' do
      phone = Phone.first
      skip 'No phones found' if phone.nil?

      chunk = Chunk.new(
        chunkable: phone,
        content: 'Test content',
        chunk_index: nil
      )
      expect(chunk).not_to be_valid
      expect(chunk.errors[:chunk_index]).to be_present
    end
  end
end
