# frozen_string_literal: true

class Presentable::DescriptionComponent < ApplicationComponent
  include MarkdownHelper
  include EoscExploreBannerHelper

  renders_one :main_options
  renders_one :sidebar_options
  renders_one :description_panels

  def initialize(object:, preview: false, from: nil)
    super()
    @object = object
    @preview = preview
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
