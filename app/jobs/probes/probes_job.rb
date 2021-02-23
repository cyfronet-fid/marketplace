# frozen_string_literal: true

class Probes::ProbesJob < ApplicationJob
  queue_as :probes

  rescue_from(StandardError) do |exception|
  end

  def perform(url, body)
    Unirest.post url, { "Content-Type" => "application/json" }, body
  end
end
