# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(project_item)
    @project_item = project_item
    @service = project_item.offer&.service # Only Service, not DeployableService
  end

  def call
    # Service opinions only apply to Service offers (not DeployableService)
    return unless @service.is_a?(Service)

    @service.update(rating: sum.fdiv(count), service_opinion_count: count)
  end

  private

  attr_reader :service, :project_item

  def sum
    ServiceOpinion
      .joins(project_item: :offer)
      .where(offers: { orderable_type: "Service", orderable_id: service.id })
      .sum(:service_rating)
  end

  def count
    service.service_opinion_count + 1
  end
end
