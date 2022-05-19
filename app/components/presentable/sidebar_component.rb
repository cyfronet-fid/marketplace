# frozen_string_literal: true

class Presentable::SidebarComponent < ApplicationComponent
  include PresentableHelper
  include Presentable::DetailsHelper
  include Presentable::SidebarHelper
  include Presentable::DetailsStyleHelper
  include ServiceHelper

  def initialize(object)
    super()
    @object = object
  end

  def sidebar_fields
    @object.instance_of?(Service) ? service_sidebar_fields : provider_sidebar_fields
  end
end
