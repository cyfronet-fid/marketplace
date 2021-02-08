# frozen_string_literal: true

class Api::V1::ResourcesController < Api::V1::ApiController
  before_action :find_and_authorize, only: [:show]
  def index
    render json: policy_scope(Service)
  end

  def show
    render json: @service
  end

  private
    def find_and_authorize
      @service = Service.friendly.find(params[:id])
      authorize @service
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Resource #{params[:id]} not found" }, status: 404
    end
end
