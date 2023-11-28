# frozen_string_literal: true

class Presentable::ProviderInfoComponent < ApplicationComponent
  include PresentableHelper
  def initialize(object:, preview: false)
    super()
    @object = object
    @preview = preview
  end

  def object_fields
    {
      website: {
        type: "url"
      },
      legal_statuses: {
        type: "object",
        value: "name",
        array: true
      },
      scientific_domains: {
        type: "object",
        value: "name",
        array: true
      }
    }
  end
end
