# frozen_string_literal: true

class Presentable::LinksComponent < ApplicationComponent
  include Presentable::LinksHelper

  def initialize(object:, preview: false)
    super()
    @object = object
    @preview = preview
  end

  def link_fields
    case @object
    when Provider
      provider_fields
    when Service
      service_fields
    end
  end
end
