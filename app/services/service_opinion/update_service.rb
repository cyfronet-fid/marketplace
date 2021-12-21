# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(project_item)
    @project_item = project_item
    @service = project_item.service
  end

  def call
    @project_item.service.update(rating: sum.fdiv(count), service_opinion_count: count)
  end

  private

  attr_reader :service, :project_item

  def sum
    ServiceOpinion.joins(project_item: :offer).where(offers: { service_id: service }).sum(:service_rating)
  end

  def count
    service.service_opinion_count + 1
  end
end
