# frozen_string_literal: true

class Offer::Publish < Offer::ApplicationService
  def call
    # Don't send Offer::Mailer::Bundled notification here, since this mini-service is only used in the context,
    # where such notifications will be sent by the caller, i.e. Service::Publish.
    @offer.update(status: :published)
  end
end
