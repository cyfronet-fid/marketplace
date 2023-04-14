# frozen_string_literal: true

class Presentable::HeaderLinksComponent < ApplicationComponent
  include Presentable::HeaderHelper

  def initialize(object:, preview: false)
    super()
    @object = object
    @preview = preview
  end

  def header_fields
    case @object
    when Provider
      provider_header_fields
    when Service
      @object.type == "Datasource" ? datasource_header_fields : service_header_fields
    end
  end
end
