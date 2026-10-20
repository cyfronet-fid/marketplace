# frozen_string_literal: true

class Provider::Reject < Provider::ApprovalDecision
  def call
    return false unless pending_decision?
    return false unless Provider::Unpublish.call(@provider)

    notify_managers { |email| ProviderMailer.rejected(@provider, email) }
    true
  end
end
