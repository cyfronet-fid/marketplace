# frozen_string_literal: true
require "action_view/helpers"

class Presentable::ListComponent < ApplicationComponent
  include ActionView::Helpers
  def initialize(collection:)
    super()
    @collection = collection
    @klass = collection.model.name.underscore
  end
end
