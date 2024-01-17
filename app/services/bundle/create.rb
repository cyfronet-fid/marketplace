# frozen_string_literal: true

class Bundle::Create < Bundle::ApplicationService
  def call
    @bundle.order_type = @bundle.main_offer.order_type if @bundle.main_offer.present?
    if @bundle.save
      notify_bundled!
      @bundle.service.reindex
    end
    @bundle
  end
end
