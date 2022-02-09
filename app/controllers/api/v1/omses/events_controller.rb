# frozen_string_literal: true

class Api::V1::OMSes::EventsController < Api::V1::ApplicationController
  include DateHelper
  before_action :find_and_authorize_oms
  before_action :validate_from_timestamp, only: :index
  before_action :validate_limit, only: :index
  before_action :load_events, only: :index

  def index
    render json: { events: @events.map { |e| Api::V1::EventSerializer.new(e) } }
  end

  private

  def load_events
    @events =
      policy_scope(@oms.events).where("events.created_at > ?", @from_timestamp).order("events.created_at").limit(@limit)
  end

  def validate_from_timestamp
    params.require(:from_timestamp)
    @from_timestamp = from_timestamp(params[:from_timestamp])
  rescue ActionController::ParameterMissing, ArgumentError => e
    render json: { error: e }, status: 400
  end
end
