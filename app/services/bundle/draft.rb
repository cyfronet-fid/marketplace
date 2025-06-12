# frozen_string_literal: true

class Bundle::Draft < Bundle::ApplicationService
  def initialize(bundle, empty_offers: false, external_update: false)
    super(bundle)
    @empty_offers = empty_offers
    @external_update = external_update
  end

  def call
    if @empty_offers
      @bundle.offers = []
    elsif !@external_update
      notify_unbundled!
    end
    @bundle.status = "draft"
    @bundle.save!(validate: false)
    @bundle
  end
end
