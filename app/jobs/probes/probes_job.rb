# frozen_string_literal: true

class Probes::ProbesJob < ApplicationJob
  queue_as :probes

  rescue_from(StandardError) { |_| nil }

  def perform(body)
    url = Mp::Application.config.recommender_host + "/user_actions"
    Faraday.post url, body, { "Content-Type": "application/json", Accept: "application/json" }
  end
end
