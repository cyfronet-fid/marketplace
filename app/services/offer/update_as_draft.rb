# frozen_string_literal: true
class Offer::UpdateAsDraft < Offer::ApplicationService
  def initialize(offer, params)
    super(offer)
    @params = params
  end

  def call
    public_before = @offer.published?
    @offer.status = "draft"
    effective_params = @offer.service.offers.published.size == 1 ? @params : @params.merge(default: false)

    if effective_params["primary_oms_id"] && OMS.find(effective_params["primary_oms_id"])&.custom_params.blank?
      effective_params["oms_params"] = {}
    end
    @offer.assign_attributes(effective_params)
    @offer.save(validate: false)
    unbundle! if public_before
    @offer.service.reindex

    @offer.valid?
  end
end
