# frozen_string_literal: true

class Presentable::DetailsComponent < ApplicationComponent
  include Presentable::DetailsHelper
  include Presentable::DetailsStyleHelper
  include PresentableHelper
  include Presentable::LinksHelper
  include ServiceHelper

  def initialize(object, similar_services: nil, related_services: nil, preview: false, guidelines: false)
    super()
    @object = object
    @guidelines = guidelines
    @preview = preview
    @similar_services = similar_services
    @related_services = related_services
  end

  def details_columns
    if @guidelines
      guidelines_details_columns
    else
      case @object
      when Provider
        provider_details_columns
      when Service
        @object.type == "Datasource" ? datasource_details_columns : service_details_columns
      end
    end
  end
end
