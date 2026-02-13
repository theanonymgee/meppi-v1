# frozen_string_literal: true

# Trades Controller - MeppiTrade CRUD operations
# Single Responsibility: Manage product trade listings with CRUD operations
# Vibe Coding: Error handling, consistent response format, single source of truth

class TradesController < ApplicationController
  # GET /trades - List all trades
  def index
    trades = MeppiTrade.all.includes(:phone, :channel, :country)

    render json: {
      data: {
        trades: trades.map { |trade| serialize_trade(trade) },
        count: trades.count
      }
    }
  end

  # GET /trades/:id - Show single trade details
  def show
    trade = MeppiTrade.find(params[:id])

    render json: { data: serialize_trade(trade) }
  end

  # GET /trades/new - New trade form
  def new
    render json: { data: { form: 'new_trade' } }
  end

  # POST /trades - Create new trade
  def create
    trade = MeppiTrade.new(trade_params)

    if trade.save
      render json: { data: serialize_trade(trade) }, status: :created
    else
      render json: { errors: trade.errors.full_messages }, status: :unprocessable_content
    end
  end

  # GET /trades/:id/edit - Edit form
  def edit
    trade = MeppiTrade.find(params[:id])

    render json: { data: serialize_trade(trade) }
  end

  # PATCH/PUT /trades/:id - Update trade
  def update
    trade = MeppiTrade.find(params[:id])

    if trade.update(trade_params)
      render json: { data: serialize_trade(trade) }, status: :ok
    else
      render json: { errors: trade.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /trades/:id - Delete trade
  def destroy
    trade = MeppiTrade.find(params[:id])
    trade.destroy

    render json: { data: { message: 'Trade deleted' } }, status: :ok
  end

  # GET /dashboard - Dashboard
  def dashboard
    render json: {
      data: {
        total_trades: MeppiTrade.count,
        recent_trades: MeppiTrade.recent.limit(10)
      }
    }
  end

  # GET /benchmark - Benchmark
  def benchmark
    render json: {
      data: {
        message: 'Benchmark endpoint - to be implemented'
      }
    }
  end

  private

  # Strong parameters for trade creation/update
  def trade_params
    params.require(:trade).permit(
      :phone_id,
      :channel_id,
      :country_id,
      :title,
      :brand,
      :price_local,
      :price_usd,
      :currency,
      :stock_status,
      :url,
      :trade_type,
      :valid_until,
      :discount_percent,
      :discount_amount_local,
      :promo_code
    )
  end

  # Serialize trade for JSON response
  # @param trade [MeppiTrade] Trade record
  # @return [Hash] Serialized trade data
  def serialize_trade(trade)
    {
      id: trade.id,
      phone_id: trade.phone_id,
      channel_id: trade.channel_id,
      country_id: trade.country_id,
      title: trade.title,
      brand: trade.brand.to_s,
      price_local: trade.price_local.to_f,
      price_usd: trade.price_usd.to_f,
      currency: trade.currency,
      stock_status: trade.stock_status,
      url: trade.url.to_s,
      trade_type: trade.trade_type,
      valid_until: trade.valid_until,
      discount_percent: trade.discount_percent,
      discount_amount_local: trade.discount_amount_local,
      promo_code: trade.promo_code,
      created_at: trade.created_at.strftime('%Y-%m-%d %H:%M'),
      updated_at: trade.updated_at.strftime('%Y-%m-%d %H:%M')
    }
  end
end
