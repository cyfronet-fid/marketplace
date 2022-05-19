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
    @object.instance_of?(Service) ? service_details_columns : provider_details_columns
  end
end
