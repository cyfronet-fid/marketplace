# frozen_string_literal: true

class Bundle::Unpublish < Bundle::ApplicationService
  def call
    unless @bundle.deleted?
      @bundle.status = :unpublished
      if @bundle.save(validate: false)
        notify_unbundled!
        @bundle.service.reindex
        @bundle.offers.reindex
      else
        return false
      end
    end
    @bundle
  end
end
