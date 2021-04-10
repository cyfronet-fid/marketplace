# frozen_string_literal: true

class Api::V1::Oms::EventsController < Api::V1::Oms::ApiController
  before_action :find_and_authorize_oms
  before_action :handle_timestamp,  only: [:index]
  before_action :handle_limit, only: [:index]
  before_action :load_events, only: [:index]

  def index
    render json: { events: @events.map { |e| OrderingApi::V1::EventSerializer.new(e) } }
  end

  private
    def load_events
      @events = policy_scope(@oms.events).limit(@limit).where("events.created_at > ?", @from_timestamp).order("events.created_at")
    end

    def handle_timestamp
      params.require(:from_timestamp)
      @from_timestamp = params[:from_timestamp].to_datetime
    rescue ActionController::ParameterMissing, ArgumentError => e
      render json: { error: e }, status: 400
    end

    def handle_limit
      @limit = params[:limit].present? ? params[:limit].to_i : 20

      if @limit <= 0
        render json: { error: "limit must be a positive integer" }, status: 400
      end
  end
end
