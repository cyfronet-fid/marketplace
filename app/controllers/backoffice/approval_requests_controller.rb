# frozen_string_literal: true

class Backoffice::ApprovalRequestsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show update]

  def index
    @approval_requests = ApprovalRequest.active.order(created_at: :desc)
  end

  def show; end
  def edit; end

  def update
    if Mp::Variant.pl?
      # pl decides through ApprovalRequest::Review: a rejected provider stays
      # unpublished and the provider managers get an email (pl-marketplace #170).
      result = ApprovalRequest::Review.call(@approval_request, reviewer: current_user, **review_params)
      @message = result.message
      success = result.success?
    else
      # marketplace and whitelabel delete a rejected provider and send no email.
      current_action = permitted_attributes(ApprovalRequest).fetch("current_action", nil)
      @approval_request.assign_attributes(
        permitted_attributes(ApprovalRequest).merge(status: assign_status(current_action), last_action: current_action)
      )
      provider_action_successful = process_provider_action(current_action)
      @message = create_message
      success = @approval_request.save && Message::Create.call(@message) && provider_action_successful
    end
    @approval_requests = ApprovalRequest.active.order(created_at: :desc)

    respond_to { |format| success ? respond_with_success(format) : respond_with_error(format) }
  end

  private

  def find_and_authorize
    @approval_request = authorize(ApprovalRequest.includes(:messages).find(params[:id]))
  end

  def review_params
    attributes = permitted_attributes(ApprovalRequest)
    { action: attributes["current_action"], text: attributes["message"] }
  end

  def assign_status(action)
    action == "requested_for_changes" || action.blank? ? :published : :deleted
  end

  def process_provider_action(current_action)
    provider = @approval_request.approvable
    case current_action
    when "accepted"
      Provider::Publish.call(provider)
    when "rejected"
      Provider::Delete.call(provider)
    else
      Provider::Unpublish.call(provider)
    end
  end

  def create_message
    Message.new(
      message: params.dig(:approval_request, :message),
      author: current_user,
      author_role: :mediator,
      scope: :user_direct,
      messageable: @approval_request
    )
  end

  def respond_with_success(format)
    notice = _("Message sent successfully")
    format.html { redirect_to backoffice_providers_path, notice: notice }
    format.turbo_stream do
      flash.now[:notice] = notice
      render :update, status: :ok
    end
  end

  def respond_with_error(format)
    flash.now[:alert] = _("Message not sent")
    format.html { render :show, status: :unprocessable_content }
    format.json { render :edit, status: :unprocessable_content }
    format.turbo_stream { render :update, status: :unprocessable_content }
  end
end
