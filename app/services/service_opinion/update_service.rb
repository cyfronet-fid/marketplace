# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(project_item)
    @project_item = project_item
    @service = project_item.offer&.service # Only Service, not DeployableService
  end

  # Recounts the Service's Opinions from the rows, so a counter that drifted
  # before heals with the next Opinion. The counters don't depend on the
  # Service's other attributes, so a Service invalid for an unrelated reason
  # (a malformed URL, say) still gets them; any other failure raises instead
  # of leaving them stale without a trace.
  def call
    # Service opinions only apply to Service offers (not DeployableService)
    return unless @service.is_a?(Service)

    @service.assign_attributes(ServiceOpinion::Totals.call(@service))
    @service.save!(validate: false)
  end
end
