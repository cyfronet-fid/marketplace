# frozen_string_literal: true

class Backoffice::Services::OffersController < Backoffice::ApplicationController
  before_action :find_service
  before_action :find_offer_and_authorize, only: %i[edit update]
  before_action :load_form_data, only: %i[fetch_subtypes]
  after_action :reindex_offer, only: %i[create update destroy]

  def index
    @offers = policy_scope(@service.offers)
    @bundles = policy_scope(@service.bundles)
    @question = Service::Question.new(service: @service)
  end

  def new
    @offer = Offer.new(service: @service)
    authorize(@offer)
  end

  def create
    save_as_draft = params[:commit] == save_as_draft_title
    template = save_as_draft ? offer_draft_template : offer_template
    authorize(template)

    if save_as_draft
      template.name = params["name"]
      @offer = Offer::CreateAsDraft.call(template)
      redirect_to backoffice_service_offers_path(@service), notice: "New offer created successfully"
      return
    else
      @offer = Offer::Create.call(template)
    end

    if @offer.persisted?
      redirect_to backoffice_service_offers_path(@service), notice: "New offer created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def submit_summary
    template = offer_template
    authorize(template)
    render partial: "backoffice/services/offers/steps/summary", locals: { offer: template }
  end

  def edit
  end

  def update
    save_as_draft = params[:commit] == save_as_draft_title
    template = permitted_attributes(Offer)
    if save_as_draft
      template[:name] = params["name"]
      Offer::UpdateAsDraft.call(@offer, transform_attributes(template, @service))
      redirect_to backoffice_service_offers_path(@service), notice: "Offer updated successfully and drafted"
      nil
    elsif Offer::Update.call(@offer, transform_attributes(template, @service))
      redirect_to backoffice_service_offers_path(@service), notice: "Offer updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @offer = @service.offers.find_by(iid: params[:id])
    if Offer::Delete.call(@offer)
      redirect_to backoffice_service_offers_path(@service), notice: "Offer removed successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def fetch_subtypes
    json = {}
    json.merge!(types: map_types(@types)) unless @types.nil?
    json.merge!(subtypes: map_types(@subtypes)) unless @subtypes.nil?
    json.merge!(parameters: @parameters) if @offer_id == "new"
    render json: json
  end

  # POST /backoffice/services/<service_slug>/offers/:id/duplicate
  def duplicate
    original_offer = @service.offers.find_by(iid: params[:offer_id])
    new_offer = original_offer.dup
    new_offer.iid = nil
    new_offer.id = nil
    new_offer.name = params["custom_form"][:new_name]
    new_offer.status = "draft"

    @offer = Offer::Create.call(new_offer)
    if @offer.persisted?
      redirect_to backoffice_service_offers_path(@service), notice: "Offer duplicated successfully"
    else
      redirect_to backoffice_service_offers_path(@service), notice: "Offer duplication errored"
    end
  end

  private

  def reindex_offer
    @service.offers.reindex if @service.offers.size > 1
  end

  def offer_template
    temp = transform_attributes(permitted_attributes(Offer), @service)
    Offer.new(temp.merge(service: @service, status: :published))
  end

  def offer_draft_template
    temp = transform_attributes(permitted_attributes(Offer), @service)
    Offer.new(temp.merge(service: @service, status: :draft))
  end

  def transform_attributes(template, service)
    template["service_id"] = service.id

    template["parameters_attributes"] = [] if template["parameters_attributes"].blank?
    template["oms_params"] = {} if template["primary_oms_id"].present? && template["oms_params"].nil?
    template.except(:from)
  end

  def find_service
    @service = Service.friendly.find(params[:service_id])
  end

  def load_form_data
    current_category_id = params[:service_category] || @offer&.offer_category_id
    parent = current_category_id.present? ? Vocabulary::ServiceCategory.find(current_category_id) : nil
    @offer_id = params[:offer_id]
    @parameters = default_parameters(parent&.eid) if @offer_id == "new"
    @types = parent&.ancestry_depth&.zero? ? find_types(parent) : nil
    @subtypes =
      if @types&.size == 1
        find_types(parent&.children&.first)
      elsif parent&.ancestry_depth == 1
        find_types(parent)
      elsif parent&.ancestry_depth&.zero?
        []
      end
  end

  def default_parameters(category)
    config = YAML.load_file("config/offer_parameters.yml", aliases: true)
    category && config&.key?(category) ? config[category].flatten : {}
  end

  def find_types(parent)
    ancestry_construct = parent.ancestry.nil? ? "#{parent.id}" : "#{parent.ancestry}/#{parent.id}"
    Vocabulary::ServiceCategory.where(ancestry: ancestry_construct, ancestry_depth: (parent.ancestry_depth + 1))
  end

  def map_types(types)
    types.map { |s| { value: s&.id, label: s&.name, selected: types&.size == 1 } }
  end

  def find_offer_and_authorize
    @offer = @service.offers.find_by(iid: params[:id])
    authorize(@offer)
  end
end
