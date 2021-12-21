# frozen_string_literal: true

class Api::V1::OMSesController < Api::V1::ApplicationController
  before_action :load_omses, only: :index
  before_action :find_and_authorize, only: :show

  def index
    render json: { omses: @omses.map { |oms| Api::V1::Ordering::OMSSerializer.new(oms).as_json } }
  end

  def show
    render json: Api::V1::Ordering::OMSSerializer.new(@oms).as_json
  end

  private

  def load_omses
    @omses = policy_scope(OMS).order(:id)
  end

  def find_and_authorize
    @oms = OMS.find(params[:id])
    authorize @oms
  rescue ActiveRecord::RecordNotFound
    render json: { error: "OMS not found" }, status: 404
  end
end
