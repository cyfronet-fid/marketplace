# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(project_item)
    @project_item = project_item
    @service = project_item.offer&.service # Only Service, not DeployableService
  end

  # Recounts the Service's Opinions from the rows, so a counter that drifted
  # before heals with the next Opinion.
  def call
    # Service opinions only apply to Service offers (not DeployableService)
    return unless @service.is_a?(Service)

    @service.update(ServiceOpinion::Totals.call(@service))
  end
end
