# frozen_string_literal: true

class Bundle::Unpublish < Bundle::ApplicationService
  def call
    if @bundle.update(status: :unpublished)
      notify_unbundled!
      @bundle.service.reindex
      @bundle.offers.reindex
    else
      return false
    end
    @bundle
  end
end
