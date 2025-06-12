# frozen_string_literal: true

class Bundle::Update < Bundle::ApplicationService
  def initialize(bundle, params, external_update: false)
    super(bundle)
    @params = params
    @external_update = external_update
    @current_offer_ids = @params[:offer_ids] || @params[:offers]&.map(&:id) || []
    @added_bundled_offer_ids = @current_offer_ids - @bundle.offers.map(&:id)
    @removed_bundled_offer_ids = @bundle.offers.map(&:id) - @current_offer_ids
  end

  def call
    if @external_update
      notify_own_offer!
      @bundle = Bundle::Draft.call(@bundle, external_update: @external_update)
      result = @bundle.update(@params)
    else
      public_before = @bundle.published?
      result = @bundle.update(@params)
      notify_bundled_offers! if result && public_before
    end
    @bundle.service.reindex
    @bundle.offers.reindex
    @bundle.reindex
    result
  end

  private

  def notify_bundled_offers!
    if @added_bundled_offer_ids.size.positive?
      Offer
        .where(id: @added_bundled_offer_ids)
        .each { |added_bundled_offer| Offer::Mailer::Bundled.call(added_bundled_offer, @bundle.main_offer) }
    end

    if @removed_bundled_offer_ids.size.positive?
      Offer
        .where(id: @removed_bundled_offer_ids)
        .each { |removed_bundled_offer| Offer::Mailer::Unbundled.call(removed_bundled_offer, @bundle.main_offer) }
    end
  end

  def notify_own_offer!
    Offer
      .where(id: @removed_bundled_offer_ids)
      .each { |removed_bundled_offer| Offer::Mailer::Unbundled.call(@bundle.main_offer, removed_bundled_offer) }
  end
end
