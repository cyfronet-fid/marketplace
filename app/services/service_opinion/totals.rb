# frozen_string_literal: true

# The Opinion counters of a Service, counted from the rows (ADR-0008
# D31): service_opinion_count is the number of Opinions given for any
# Project item of its Offers, and rating the average of their Service
# ratings, or 0 without any. Both come from the same rows.
class ServiceOpinion::Totals < ApplicationService
  def initialize(service)
    super()
    @service = service
  end

  # The attributes to store on the Service.
  def call
    ratings = ServiceOpinion.arel_table[:service_rating]
    count, average = @service.service_opinions.pick(Arel.star.count, ratings.average)

    { service_opinion_count: count, rating: average || 0 }
  end
end
