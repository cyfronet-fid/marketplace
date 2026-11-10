# frozen_string_literal: true

class Provider::SubmitForApproval < Provider::ApplicationService
  def initialize(provider, user)
    super(provider)
    @user = user
  end

  def call
    return unless approval_required?

    existing_request = @provider.approval_requests.active.find_by(user: @user)
    return existing_request if existing_request.present?

    approval_request = ApprovalRequest.create(approvable: @provider, user: @user, status: :published)
    ProviderMailer.waiting_for_approval(approval_request).deliver_later if approval_request.persisted?

    approval_request
  end

  private

  def approval_required?
    !@user.coordinator? && !@user.providers.published.exists?
  end
end
