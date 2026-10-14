# frozen_string_literal: true

class Provider::RequestChanges < Provider::ApprovalDecision
  def call
    return false unless pending_decision?
    return false unless Provider::Unpublish.call(@provider)

    notify_managers { |email| ProviderMailer.changes_requested(@message, email) }
    true
  end
end
