# frozen_string_literal: true

class Ams::Handlers::Guideline < Ams::Handlers::Base
  private

  def delete(id)
    ::Guideline::DeleteJob.perform_later(id)
  end

  def create_or_update(payload)
    ::Guideline::PcCreateOrUpdateJob.perform_later(payload, status, modified_at)
  end
end
