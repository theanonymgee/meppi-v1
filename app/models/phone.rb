# frozen_string_literal: true

class Phone < ApplicationRecord
  has_many :prices, dependent: :destroy
  has_many :meppi_trades, dependent: :destroy
  has_many :promotions, dependent: :destroy
  has_many :dubai_benchmarks, dependent: :destroy
  has_many :chunks, dependent: :destroy

  validates :brand, presence: true
  validates :url, presence: true, uniqueness: true

  # NOTE: 106 phones have empty model field in source data

  # Enable pgvector for semantic search (RAG)
  # has_neighbors :embedding  # Uncomment when pgvector gem is properly configured

  scope :recent, -> { order(created_at: :desc) }
  scope :by_brand, ->(brand) { where(brand:) }

  # Helper methods for embedding generation
  def display_type
    # Extract display type from display_size or return a default
    return '6.7 inches' if display_size.present?

    'Smartphone'
  end

  def camera_specs
    # Extract main camera specs from main_camera field
    return main_camera if main_camera.present?

    'Unknown camera'
  end

  def full_name
    "#{brand} #{model}".strip
  end
end
