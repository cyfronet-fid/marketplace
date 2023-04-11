# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class OfferPreview < ActionMailer::Preview
  def offer_bundled
    OfferMailer.offer_bundled(
      Bundle.first,
      Bundle.first.offers.first,
      Bundle.first.service.resource_organisation.data_administrators.map(&:email)
    )
  end

  def offer_unbundled
    OfferMailer.offer_unbundled(
      Bundle.first,
      Bundle.first.offers.first,
      Bundle.first.service.resource_organisation.data_administrators.map(&:email)
    )
  end
end
