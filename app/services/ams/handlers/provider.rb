# frozen_string_literal: true

class Ams::Handlers::Provider < Ams::Handlers::Base
  private

  def delete(id)
    ::Provider::DeleteJob.perform_later(id)
  end

  def create_or_update(payload)
    ::Provider::PcCreateOrUpdateJob.perform_later(payload, status, modified_at)
  end
end
