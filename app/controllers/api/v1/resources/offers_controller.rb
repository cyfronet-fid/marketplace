# frozen_string_literal: true

require "json-schema"

class Api::V1::Resources::OffersController < Api::V1::ApplicationController
  before_action :find_service
  before_action :load_offers, only: :index
  before_action :find_and_authorize, only: %i[show update destroy]
  before_action :validate_payload, only: %i[create update]
  before_action :load_bundled_offers, only: %i[create update]
  after_action :reindex_offer, only: %i[create update destroy]

  def index
    render json: { offers: @offers.map { |o| Api::V1::OfferSerializer.new(o).as_json } }
  end

  def show
    render json: Api::V1::OfferSerializer.new(@offer).as_json
  end

  def create
    offer_temp = offer_template
    authorize offer_temp

    @offer = Offer::Create.call(offer_temp)

    if @offer.persisted?
      render json: Api::V1::OfferSerializer.new(@offer).as_json, status: 201
    else
      render json: { error: @offer.errors.to_hash }, status: 400
    end
  end

  def update
    template = transform(permitted_attributes(@offer))
    if Offer::Update.call(@offer, template)
      render json: Api::V1::OfferSerializer.new(@offer).as_json, status: 200
    else
      render json: { error: @offer.errors.to_hash }, status: 400
    end
  end

  def destroy
    Offer::Delete.call(@offer)
    head :ok
  end

  private

  def permitted_attributes(record)
    super
  rescue ActionController::ParameterMissing => e
    if @bundled_offers.is_a?(Array)
      {}
    else
      raise e
    end
  end

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
    render json: { error: "Offer not found" }, status: 404
  end

  def validate_payload
    JSON::Validator.validate!(payload_schema_path, request.body.read)
  rescue JSON::Schema::ValidationError => e
    render json: { error: e.message }, status: 400
  end

  def payload_schema_path
    schema_file = action_name == "create" ? "offer_write.json" : "offer_update.json"
    Rails.root.join("swagger", "v1", "offer", schema_file).to_s
  end

  def load_bundled_offers
    main_bundles = params[:main_bundles]
    unless main_bundles.nil?
      if main_bundles.is_a?(Hash) && main_bundles.values.flatten.all? { |o| o.is_a?(String) }
        @bundled_offers = main_bundles.map { |val| Offer.find_by_slug_iid!(val) }
      else
        render json: { error: "Bundled offers must be an array of strings" }, status: 400
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    msg =
      case e.message
      when /Service/
        "A bundled offer's resource not found"
      when /Offer/
        "A bundled offer not found"
      else
        Sentry.capture_message("Unexpected exception message '#{e.message}'")
        "Not found"
      end
    render json: { error: msg }, status: 400
  end

  def mapped_bundled_offers
    @bundled_offers.is_a?(Hash) ? { bundled_offers: @bundled_offers } : {}
  end

  def transform(attributes)
    attributes[:parameters] = Parameter::Array.load(attributes[:parameters]) if attributes[:parameters].present?
    attributes[:offer_category] = Vocabulary::ServiceCategory.find_by(eid: params[:offer_category]) if params[
      :offer_category
    ].present?
    attributes.merge(mapped_bundled_offers)
  end

  def offer_template
    Offer.new(transform(permitted_attributes(Offer)).merge(service: @service, status: :published))
  end

  def reindex_offer
    @service.offers.reindex if @service.offers.size > 1
  end
end
