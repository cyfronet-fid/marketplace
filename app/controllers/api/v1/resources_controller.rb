# frozen_string_literal: true

class Api::V1::ResourcesController < Api::V1::ApplicationController
  before_action :load_services, only: :index
  before_action :find_and_authorize, only: :show

  def index
    render json: { resources: @services.map { |s| Api::V1::ServiceSerializer.new(s).as_json } }
  end

  def show
    render json: Api::V1::ServiceSerializer.new(@service).as_json
  end

  private

  def load_services
    @services = policy_scope(Service).order(:id)
  end

  def find_and_authorize
    @service = Service.friendly.find(params[:id])
    authorize @service
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource not found" }, status: 404
  end
end
