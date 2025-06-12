# frozen_string_literal: true

class Backoffice::OtherSettings::VocabulariesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]
  before_action :instantiate_type

  def index
    authorize(vocabulary_type)
    @vocabularies = vocabulary_type.all.order(:name)
    @all_types = VOCABULARY_TYPES.map { |k, v| [v[:name], k.to_s.pluralize.to_sym] }
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
      redirect_to send("backoffice_other_settings_#{@vocabulary.model_name.element}_path", @vocabulary),
                  notice: "New #{VOCABULARY_TYPES[@vocabulary.model_name.element.to_sym][:name]} created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @vocabulary.update(permitted_attributes(@vocabulary))
      redirect_to send("backoffice_other_settings_#{@vocabulary.model_name.element}_path", @vocabulary),
                  notice: "#{VOCABULARY_TYPES[@vocabulary.model_name.element.to_sym][:name]} updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if @vocabulary.descendant_ids.present?
      redirect_back fallback_location:
                      send("backoffice_other_settings_#{@vocabulary.model_name.element}_path", @vocabulary),
                    alert:
                      "This #{@type} has successors connected to it,
                            therefore is not possible to remove it. If you want to remove it,
                            edit them so they are not associated with this #{@type} anymore"
    elsif @vocabulary.try(:services).present?
      redirect_back fallback_location:
                      send("backoffice_other_settings_#{@vocabulary.model_name.element}_path", @vocabulary),
                    alert: "This vocabulary has services connected to it, remove associations to delete it."
    elsif @vocabulary.try(:providers).present?
      redirect_back fallback_location:
                      send("backoffice_other_settings_#{@vocabulary.model_name.element}_path", @vocabulary),
                    alert: "This vocabulary has providers connected to it, remove associations to delete it."
    else
      @vocabulary.destroy!
      redirect_to send("backoffice_other_settings_#{@vocabulary.model_name.element.pluralize}_path"),
                  notice: "#{@type} removed successfully"
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
    VOCABULARY_TYPES[params[:type].to_sym][:klass].constantize
  end
end
