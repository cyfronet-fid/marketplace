# frozen_string_literal: true

class Presentable::DescriptionComponent < ApplicationComponent
  include Presentable::LinksHelper
  include MarkdownHelper
  include SearchLinksHelper
  include ServiceHelper

  renders_one :main_options
  renders_one :additional_backoffice_info
  renders_one :description_panels

  def initialize(object:, similar_services: nil, related_services: nil, preview: false, question: nil, from: nil)
    super()
    @object = object
    @preview = preview
    @similar_services = similar_services
    @related_services = related_services
    @question = question
    @from = from
  end

  def details_link
    case @object
    when Service
      service_details_path(@object, @from.present? ? { from: @from } : nil)
    when Provider
      provider_details_path(@object, @from.present? ? { from: @from } : nil)
    when Datasource
      datasource_details_path(@object, @from.present? ? { from: @from } : nil)
    end
  end
end
