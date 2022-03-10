# frozen_string_literal: true

class Ess::UpdateJob < ApplicationJob
  queue_as :ess_update

  def perform(payload)
    Ess::Update.call(payload)
  end
end
