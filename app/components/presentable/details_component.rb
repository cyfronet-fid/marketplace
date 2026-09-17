# frozen_string_literal: true

class Presentable::DetailsComponent < ApplicationComponent
  include Presentable::DetailsStyleHelper
  include Presentable::LinksHelper
  include PresentableHelper
  include ServiceHelper

  def initialize(
    object,
    similar_services: nil,
    related_services: nil,
    preview: false,
    question: nil,
    guidelines: false,
    from: nil
  )
    super()
    @object = object
    @guidelines = guidelines
    @preview = preview
    @similar_services = similar_services
    @related_services = related_services
    @question = question
    @from = from
  end

  def deployable_application?
    resource_type == "DeployableApplication"
  end

  def service?
    resource_type.casecmp?("service")
  end

  def catalogue?
    @object.is_a?(Catalogue)
  end

  def provider?
    @object.is_a?(Provider)
  end

  private

  def resource_type
    @object.respond_to?(:resource_type) ? @object.resource_type.to_s : ""
  end
end
