# frozen_string_literal: true

class ApprovalRequest::Review < ApplicationService
  DECISIONS = {
    "accepted" => Provider::Approve,
    "rejected" => Provider::Reject,
    "requested_for_changes" => Provider::RequestChanges
  }.freeze

  Result = Struct.new(:success, :message, keyword_init: true) { alias_method :success?, :success }

  def initialize(approval_request, reviewer:, action:, text:)
    super()

    @approval_request = approval_request
    @reviewer = reviewer
    @action = action.presence
    @text = text
  end

  def call
    build_message
    assign_review

    Result.new(success: valid? && persist, message: message)
  end

  private

  attr_reader :approval_request, :reviewer, :action, :text, :message

  def build_message
    return if text.blank?

    @message =
      Message.new(
        messageable: approval_request,
        author: reviewer,
        message: text,
        author_role: :mediator,
        scope: :user_direct
      )
  end

  def assign_review
    approval_request.assign_attributes(
      status: ApprovalRequest::CLOSING_ACTIONS.include?(action) ? :deleted : :published,
      message: message&.message,
      current_action: action,
      last_action: action
    )
  end

  def valid?
    [approval_request, message].compact.map(&:valid?).all?
  end

  def persist
    ApprovalRequest.transaction(requires_new: true) do
      raise ActiveRecord::Rollback unless save_message && apply_decision && approval_request.save

      true
    end || false
  end

  def save_message
    return true if message.nil?

    Message::Create.call(message)
  end

  def apply_decision
    decision = DECISIONS[action]
    return true if decision.nil?

    decision.call(approval_request, message)
  end
end
