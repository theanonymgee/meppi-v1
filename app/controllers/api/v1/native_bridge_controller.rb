# frozen_string_literal: true

module Api
  module V1
    # NativeBridge Controller for Hotwire Native integration
    # Returns navigation structure for native mobile apps
    class NativeBridgeController < ApplicationController
      def navigation
        render json: {
          tabs: [
            { id: 'channel', label: 'Channel Price', path: '/dashboard/channel_comparison' },
            { id: 'competition', label: 'Competition', path: '/competition' },
            { id: 'promotion', label: 'Promotion', path: '/promotion' },
            { id: 'regional', label: 'Regional', path: '/regional_price' }
          ]
        }
      end
    end
  end
end
