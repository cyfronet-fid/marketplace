# frozen_string_literal: true

class Infrastructure::DestroyJob < ApplicationJob
  queue_as :default

  def perform(infrastructure_id)
    infrastructure = Infrastructure.find_by(id: infrastructure_id)
    return unless infrastructure&.can_destroy?

    Rails.logger.info "Destroying Infrastructure #{infrastructure.id} (ADM deployment: #{infrastructure.deployment_id})"
    Infrastructure::Destroy.call(infrastructure)
  end
end
