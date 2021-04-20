# frozen_string_literal: true

class Api::V1::OmsController < Api::V1::Oms::ApiController
  before_action :find_and_authorize, only: [:show, :update]
  before_action :load_oms, only: [:index]

  def index
    render json: { "OMS": @oms.map { |oms| OrderingApi::V1::OmsSerializer.new(oms).as_json } }
  end

  def show
    render json: OrderingApi::V1::OmsSerializer.new(@oms).as_json
  end

  def update
    # TODO: implement endpoint functionality
    render json: { "message": "Not yet implemented" }
  end

  private
    def load_oms
      @oms = policy_scope(Oms).order(:id)
    end

    def find_and_authorize
      @oms = Oms.find(params[:id])
      authorize @oms
    rescue ActiveRecord::RecordNotFound
      render json: { error: "OMS not found" }, status: 404
    end
end
