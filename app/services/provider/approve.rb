# frozen_string_literal: true

class Provider::Approve < Provider::ApprovalDecision
  def call
    return false unless pending_decision?
    return false unless Provider::Publish.call(@provider)

    notify_managers { |email| ProviderMailer.approved(@provider, email) }
    true
  end
end
