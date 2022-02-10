# frozen_string_literal: true

class Presentable::HeaderLinksComponent < ApplicationComponent
  include Presentable::HeaderHelper

  def initialize(object:, preview: false)
    super()
    @object = object
    @preview = preview
  end

  def header_fields
    @object.instance_of?(Service) ? service_header_fields : provider_header_fields
  end
end
