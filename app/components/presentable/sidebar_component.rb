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
    case @object
    when Service, Datasource
      service_sidebar_fields
    when Provider
      provider_sidebar_fields
    end
  end
end
