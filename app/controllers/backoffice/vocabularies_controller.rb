# frozen_string_literal: true

class Backoffice::VocabulariesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :instantiate_type

  VOCABULARY_TYPES = {
    target_user: { name: "Target User", klass: TargetUser },
    access_mode: { name: "Access Mode", klass: Vocabulary::AccessMode },
    access_type: { name: "Access Type", klass: Vocabulary::AccessType },
    funding_body: { name: "Funding Body", klass: Vocabulary::FundingBody },
    funding_program: { name: "Funding Program", klass: Vocabulary::FundingProgram },
    trl: { name: "TRL", klass: Vocabulary::Trl },
    life_cycle_status: { name: "Life Cycle Status", klass: Vocabulary::LifeCycleStatus },
    provider_life_cycle_status: { name: "Provider Life Cycle Status", klass: Vocabulary::ProviderLifeCycleStatus },
    area_of_activity: { name: "Area of Activity", klass: Vocabulary::AreaOfActivity },
    esfri_domain: { name: "ESFRI Domain", klass: Vocabulary::EsfriDomain },
    esfri_type: { name: "ESFRI Type", klass: Vocabulary::EsfriType },
    legal_status: { name: "Legal Status", klass: Vocabulary::LegalStatus },
    network: { name: "Network", klass: Vocabulary::Network },
    societal_grand_challenge: { name: "Societal Grand Challenge", klass: Vocabulary::SocietalGrandChallenge },
    structure_type: { name: "Structure Type", klass: Vocabulary::StructureType },
    meril_scientific_domain: { name: "MERIL Scientific Domain", klass: Vocabulary::MerilScientificDomain }
  }

  def index
    authorize(vocabulary_type)
    @vocabularies = vocabulary_type.all.order(:name)
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
                  notice: "New #{VOCABULARY_TYPES[@vocabulary.model_name.element.to_sym][:name]} created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @vocabulary.update(permitted_attributes(@vocabulary))
      redirect_to send("backoffice_#{@vocabulary.model_name.element}_path", @vocabulary),
                  notice: "#{VOCABULARY_TYPES[@vocabulary.model_name.element.to_sym][:name]} updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if @vocabulary.descendant_ids.present?
      redirect_back fallback_location:  send("backoffice_#{@vocabulary.model_name.element}_path", (@vocabulary)),
                    alert: "This #{@type} has successors connected to it,
                            therefore is not possible to remove it. If you want to remove it,
                            edit them so they are not associated with this #{@type} anymore"
    elsif @vocabulary.try(:services).present?
      redirect_back fallback_location:  send("backoffice_#{@vocabulary.model_name.element}_path", (@vocabulary)),
                    alert: "This vocabulary has resources connected to it, remove associations to delete it."
    elsif @vocabulary.try(:providers).present?
      redirect_back fallback_location:  send("backoffice_#{@vocabulary.model_name.element}_path", (@vocabulary)),
                    alert: "This vocabulary has providers connected to it, remove associations to delete it."
    else
      @vocabulary.destroy!
      redirect_to send("backoffice_#{@vocabulary.model_name.element.pluralize}_path"),
                  notice: "#{@type} removed"
    end
  end

  private
    def find_and_authorize
      @vocabulary = vocabulary_type.find(params[:id])
      authorize(@vocabulary)
    end

    def instantiate_type
      @type = VOCABULARY_TYPES[params[:type].to_sym][:name]
    end

    def vocabulary_type
      VOCABULARY_TYPES[params[:type].to_sym][:klass]
    end
end
