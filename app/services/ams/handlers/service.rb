# frozen_string_literal: true

class Ams::Handlers::Service < Ams::Handlers::Base
  private

  def delete(id)
    ::Service::DeleteJob.perform_later(id)
  end

  def create_or_update(payload)
    ::Service::PcCreateOrUpdateJob.perform_later(payload, status, modified_at)
  end
end
