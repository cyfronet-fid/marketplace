# frozen_string_literal: true

class Presentable::SidebarComponent < ApplicationComponent
  include PresentableHelper
  include Presentable::SidebarHelper
  include ServiceHelper

  def initialize(object)
    super()
    @object = object
  end

  def sidebar_fields
    @object.instance_of?(Service) ? service_sidebar_fields : provider_sidebar_fields
  end
end
