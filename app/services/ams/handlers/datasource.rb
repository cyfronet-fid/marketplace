# frozen_string_literal: true

class Ams::Handlers::Datasource < Ams::Handlers::Base
  private

  def delete(id)
    ::Datasource::DeleteJob.perform_later(id)
  end

  def create_or_update(payload)
    ::Datasource::PcCreateOrUpdateJob.perform_later(payload, status, modified_at)
  end
end
