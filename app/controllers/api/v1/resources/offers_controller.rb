# frozen_string_literal: true

require "json-schema"

class Api::V1::Resources::OffersController < Api::V1::ApplicationController
  before_action :find_service
  before_action :load_offers, only: :index
  before_action :find_and_authorize, only: [:show, :update, :destroy]
  before_action :validate_payload, only: [:create, :update]
  after_action :reindex_offer, only: [:create, :update, :destroy]

  def index
    render json: { offers: @offers.map { |o| Api::V1::OfferSerializer.new(o).as_json } }
  end

  def show
    render json: Api::V1::OfferSerializer.new(@offer).as_json
  end

  def create
    offer_temp = offer_template
    authorize offer_temp

    @offer = Offer::Create.new(offer_temp).call

    if @offer.persisted?
      render json: Api::V1::OfferSerializer.new(@offer).as_json, status: 201
    else
      render json: { error: @offer.errors.to_hash }, status: 400
    end
  end

  def update
    template = transform(permitted_attributes(@offer))
    if Offer::Update.new(@offer, template).call
      render json: Api::V1::OfferSerializer.new(@offer).as_json, status: 200
    else
      render json: { error: @offer.errors.to_hash }, status: 400
    end
  end

  def destroy
    Offer::Destroy.new(@offer).call
    head :ok
  end

  private
    def find_service
      @service = Service.friendly.find(params[:resource_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Resource not found" }, status: 404
    end

    def load_offers
      @offers = policy_scope(@service.offers).order(:iid)
    end

    def find_and_authorize
      @offer = @service.offers.find_by!(iid: params[:id])
      authorize @offer
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Offer not found." }, status: 404
    end

    def validate_payload
      schema_file = (action_name == "create") ? "offer_write.json" : "offer_update.json"
      JSON::Validator.validate!(Rails.root.join("swagger", "v1", "offer", schema_file).to_s, params[:offer].as_json)
    rescue JSON::Schema::ValidationError => e
      render json: { error: e.message }, status: 400
    end

    def transform(attributes)
      if attributes[:parameters].present?
        attributes[:parameters] = Parameter::Array.load(attributes[:parameters])
      end
      attributes
    end

    def offer_template
      temp = transform(permitted_attributes(Offer))
      Offer.new(temp.merge(service: @service, status: :published))
    end

    def reindex_offer
      if @service.offers.size > 1
        @service.offers.reindex
      end
    end
end
