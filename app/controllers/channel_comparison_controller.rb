# frozen_string_literal: true

class ChannelComparisonController < ApplicationController
  def index
    @countries = Country.active.order(:priority)
    @channels = Channel.active.includes(:country).order(:name)
  end
end
