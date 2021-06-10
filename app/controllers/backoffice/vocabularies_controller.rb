# frozen_string_literal: true

class Backoffice::VocabulariesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :instantiate_type

  VOCABULARY_TYPES = {
    "TargetUser": "Target User",
    "Vocabulary::AccessMode": "Access Mode",
    "Vocabulary::AccessType": "Access Type",
    "Vocabulary::FundingBody": "Funding Body",
    "Vocabulary::FundingProgram": "Funding Program",
    "Vocabulary::Trl": "TRL",
    "Vocabulary::LifeCycleStatus": "Life Cycle Status",
    "Vocabulary::ProviderLifeCycleStatus": "Provider Life Cycle Status",
    "Vocabulary::AreaOfActivity": "Area of Activity",
    "Vocabulary::EsfriDomain": "ESFRI Domain",
    "Vocabulary::EsfriType": "ESFRI Type",
    "Vocabulary::LegalStatus": "Legal Status",
    "Vocabulary::Network": "Network",
    "Vocabulary::SocietalGrandChallenge": "Societal Grand Challenge",
    "Vocabulary::StructureType": "Structure Type",
    "Vocabulary::MerilScientificDomain": "MERIL Scientific Domain"
  }

  def index
    authorize(Vocabulary)
    @pagy, @vocabularies = pagy(vocabulary_type.all.order(:name))
  end

  def show
  end

  def new
    @vocabulary = vocabulary_type.new
    authorize(@vocabulary)
  end

  def create
    @vocabulary = vocabulary_type.new(permitted_attributes(vocabulary_type))
    authorize(@vocabulary)

    if @vocabulary.save
      redirect_to send("backoffice_#{@vocabulary.model_name.element}_path", @vocabulary),
                  notice: "New access mode created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @vocabulary.update(permitted_attributes(@vocabulary))
      redirect_to send("backoffice_#{@vocabulary.model_name.element}_path", @vocabulary),
                  notice: "#{@vocabulary.model_name.element.humanize} updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if @vocabulary.descendant_ids.blank?
      @vocabulary.destroy!
      redirect_to send("backoffice_#{@vocabulary.model_name.element.pluralize}_path"),
                  notice: "#{@vocabulary.model_name.element.humanize} removed"
    else
      redirect_to send("backoffice_#{@vocabulary.model_name.element}_path", (@vocabulary)),
                  alert: "This #{@vocabulary.model_name.element.humanize} has successors connected to it,
                      therefore is not possible to remove it. If you want to remove it,
                      please go to the #{@vocabulary.model_name.element.humanize} list view
                      and edit them so they are not associated
                      with this #{@vocabulary.model_name.element.humanize} anymore"
    end
  end

  private
    def find_and_authorize
      @vocabulary = Vocabulary.find(params[:id])
      authorize(@vocabulary)
    end

    def instantiate_type
      @type = VOCABULARY_TYPES[params[:type].to_sym]
    end

    def vocabulary_type
      params[:type].constantize if params[:type].to_sym.in? VOCABULARY_TYPES.keys
    end
end
