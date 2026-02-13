# frozen_string_literal: true

require "test_helper"

class DashboardConfigurationTest < ActiveSupport::TestCase
  test "application should not be in API-only mode" do
    # Rails should render views, not just JSON
    refute Rails.configuration.api_only, "Application should serve web views, not API-only"
  end

  test "turbo-rails gem should be available" do
    assert Gem::Specification.stubs_for_turbo_rails, "turbo-rails gem should be loaded"
  end

  test "stimulus-rails gem should be available" do
    assert Gem::Specification.stubs_for_stimulus_rails, "stimulus-rails gem should be loaded"
  end

  test "tailwindcss-rails gem should be available" do
    assert Gem::Specification.stubs_for_tailwindcss_rails, "tailwindcss-rails gem should be loaded"
  end

  test "importmap should pin chart.js" do
    importmap = Rails.root.join("config/importmap.rb")
    assert File.exist?(importmap), "importmap.rb should exist"

    content = File.read(importmap)
    assert_includes content, "chart.js", "chart.js should be pinned in importmap"
  end

  test "dashboard views directory should exist" do
    views_dir = Rails.root.join("app/views/dashboard")
    assert Dir.exist?(views_dir), "Dashboard views directory should exist"
  end

  test "application layout should exist" do
    layout_path = Rails.root.join("app/views/layouts/application.html.erb")
    assert File.exist?(layout_path), "Application layout should exist"
  end

  test "application layout should include Google Fonts" do
    layout_path = Rails.root.join("app/views/layouts/application.html.erb")
    layout_content = File.read(layout_path)

    assert_includes layout_content, "Playfair Display", "Should include Playfair Display font"
    assert_includes layout_content, "Source Sans Pro", "Should include Source Sans Pro font"
    assert_includes layout_content, "IBM Plex Mono", "Should include IBM Plex Mono font"
  end
end
