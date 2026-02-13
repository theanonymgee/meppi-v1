# frozen_string_literal: true

module Api
  module V1
    # NativeBridge Controller for Hotwire Native integration
    # Returns navigation structure for native mobile apps
    class NativeBridgeController < ApplicationController
      def navigation
        render json: {
          tabs: [
            { id: 'channel', label: 'Channel Price', path: channel_comparison_path },
            { id: 'competition', label: 'Competition', path: competition_path },
            { id: 'promotion', label: 'Promotion', path: promotion_path },
            { id: 'regional', label: 'Regional', path: regional_price_path }
          ]
        }
      end
    end
  end
end
