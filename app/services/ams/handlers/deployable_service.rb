# frozen_string_literal: true

class Ams::Handlers::DeployableService < Ams::Handlers::Base
  private

  def delete(id)
    ::DeployableService::DeleteJob.perform_later(id)
  end

  def create_or_update(payload)
    ::DeployableService::PcCreateOrUpdateJob.perform_later(payload, status)
  end
end
