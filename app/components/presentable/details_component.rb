# frozen_string_literal: true

class Presentable::DetailsComponent < ApplicationComponent
  include Presentable::DetailsHelper
  include Presentable::DetailsStyleHelper
  include PresentableHelper

  def initialize(object, preview: false)
    super()
    @object = object
    @preview = preview
  end

  def details_columns
    case @object
    when Provider
      provider_details_columns
    when Service
      @object.type == "Datasource" ? datasource_details_columns : service_details_columns
    end
  end
end
