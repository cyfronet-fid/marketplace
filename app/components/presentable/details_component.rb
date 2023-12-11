# frozen_string_literal: true

class Presentable::DetailsComponent < ApplicationComponent
  include Presentable::DetailsHelper
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

  def details_columns
    if @guidelines
      guidelines_details_columns
    else
      case @object
      when Provider
        provider_details_columns
      when Service
        @object.type == "Datasource" ? datasource_details_columns(@object) : service_details_columns(@object)
      end
    end
  end
end
