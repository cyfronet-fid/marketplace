# frozen_string_literal: true

class DeleteJob < ApplicationJob
  queue_as :default

  def perform(object)
    "#{object.class}::Delete".constantize.call(object)
  end
end
