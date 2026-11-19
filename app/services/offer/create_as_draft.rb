# frozen_string_literal: true

class Offer::CreateAsDraft < Offer::ApplicationService
  def call
    # A draft skips the validation of the offer. Only the name is mandatory.
    if @offer.name.blank?
      @offer.errors.add(:name, :blank)
      return @offer
    end

    @offer.save(validate: false)
    @service.reindex
    @offer.reindex
    @offer
  end
end
