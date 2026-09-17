# frozen_string_literal: true

class UnpublishJob < ApplicationJob
  queue_as :default

  def perform(object)
    "#{object.class}::Unpublish".constantize.call(object)
  end
end
