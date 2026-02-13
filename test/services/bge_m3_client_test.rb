# frozen_string_literal: true

require "test_helper"

class BgeM3ClientTest < ActiveSupport::TestCase
  setup do
    @client = BgeM3Client.new
  end

  test "generate should return array of floats when server is running" do
    skip "BGE-M3 server needs to be running for this test" unless server_running?

    embedding = @client.generate("Samsung Galaxy S24 Ultra")

    assert_instance_of Array, embedding
    assert_equal 1024, embedding.length, "BGE-M3 should return 1024 dimensions"
    assert_instance_of Float, embedding.first
    assert embedding.all? { |v| v.is_a?(Float) && v >= -1 && v <= 1 }, "All values should be normalized"
  end

  test "generate should handle empty text" do
    assert_raises(ArgumentError) do
      @client.generate("")
    end
  end

  test "generate should handle nil text" do
    assert_raises(ArgumentError) do
      @client.generate(nil)
    end
  end

  test "health_check should return true when server is running" do
    skip "BGE-M3 server needs to be running for this test" unless server_running?

    result = @client.health_check
    assert_equal true, result
  end

  test "health_check should return false when server is down" do
    client = BgeM3Client.new(base_url: "http://localhost:9999")

    assert_equal false, client.health_check
  end

  private

  def server_running?
    @client.health_check
  rescue StandardError
    false
  end
end
