# frozen_string_literal: true

class Bundle::Draft < Bundle::ApplicationService
  def initialize(bundle, empty_offers: false)
    super(bundle)
    @empty_offers = empty_offers
  end

  def call
    if @empty_offers
      @bundle.offers = []
    else
      notify_unbundled!
    end
    @bundle.status = "draft"
    @bundle.save!(validate: false)
    @bundle
  end
end
