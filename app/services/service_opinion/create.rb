# frozen_string_literal: true

class ServiceOpinion::Create
  def initialize(service_opinion)
    @service_opinion = service_opinion
  end

  def call
    @service_opinion.save

    @service_opinion
  end
end
