# frozen_string_literal: true

require "json-schema"

class Api::V1::Services::OffersController < Api::V1::ApiController
  before_action :find_and_authorize_service
  before_action :find_and_authorize_offer, only: [:show, :update, :destroy]
  before_action :validate_payload, only: [:create, :update]
  after_action :reindex_offer, only: [:create, :update, :destroy]

  def index
    render json: policy_scope(@service.offers)
  end

  def show
    render json: @offer
  end

  def create
    offer_temp = offer_template
    authorize(offer_temp)

    @offer = Offer::Create.new(offer_temp).call

    if @offer.persisted?
      render json: @offer, status: 201
    else
      render json: { error: @offer.errors.messages }, status: 400
    end
  end

  def update
    template = transform_parameters(permitted_attributes(Offer))
    if Offer::Update.new(@offer, template).call
      render json: @offer, status: 200
    else
      render json: { error: @offer.errors.messages }, status: 400
    end
  end

  def destroy
    Offer::Destroy.new(@offer).call
    head :ok
  end

  private
    def find_and_authorize_service
      @service = Service.friendly.find(params[:service_id])
      authorize @service, :administered_by?
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Service #{params[:service_id]} not found" }, status: 404
    end

    def find_and_authorize_offer
      @offer = @service.offers.find_by!(iid: params[:id])
      authorize @offer
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Offer #{params[:id]} for service #{params[:service_id]} not found." }, status: 404
    end

    def validate_payload
      schema_file = (action_name == "create") ? "offer_input.json" : "offer_update.json"
      JSON::Validator.validate!(Rails.root.join("swagger", "v1", "offer", schema_file).to_s, params["offer"].as_json)
    rescue JSON::Schema::ValidationError => e
      render json: { error: e.message }, status: 400
    end

    def reindex_offer
      if @service.offers.size > 1
        @service.offers.reindex
      end
    end

    def offer_template
      temp = transform_parameters(permitted_attributes(Offer))
      Offer.new(temp.merge(service: @service, status: :published))
    end

    def transform_parameters(template)
      unless template["parameters"].blank?
        template["parameters"] = Parameter::Array.load(template["parameters"])
      end
      template
    end
end
