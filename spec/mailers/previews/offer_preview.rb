# frozen_string_literal: true

# Preview all emails at ${ROOT_URL}/rails/mailers/project_item
#
# !!! We are using last created offer and user to show email previews !!!
class OfferPreview < ActionMailer::Preview
  def available
    OfferMailer.notify_watcher(Offer.last, User.last)
  end

  def expired
    OfferMailer.notify_provider(Offer.last, User.last)
  end
end
