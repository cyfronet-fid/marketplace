# frozen_string_literal: true

class SuspendJob < ApplicationJob
  queue_as :default

  def perform(object)
    "#{object.class}::Suspend".constantize.call(object)
  end
end
