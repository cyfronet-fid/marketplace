# frozen_string_literal: true

class Offer::Update < Offer::ApplicationService
  def initialize(offer, params)
    super(offer)
    @params = params
  end

  def call
    public_before = @offer.published?
    effective_params = @offer.service.offers.published.size == 1 ? @params : @params.merge(default: false)

    if effective_params["primary_oms_id"] && OMS.find(effective_params["primary_oms_id"])&.custom_params.blank?
      effective_params["oms_params"] = {}
    end
    @offer.update(effective_params)
    unbundle! if !@offer.published? && public_before
    @offer.service.reindex
    @offer.valid?
  end
end
