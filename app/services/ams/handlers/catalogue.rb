# frozen_string_literal: true

class Ams::Handlers::Catalogue < Ams::Handlers::Base
  private

  def delete(id)
    Ams::Logger.info("Ignoring catalogue delete for id '#{id}': catalogue deletion is not supported")
    nil
  end

  def create_or_update(payload)
    ::Catalogue::PcCreateOrUpdateJob.perform_later(payload, status, modified_at)
  end
end
