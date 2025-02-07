# frozen_string_literal: true

class Backoffice::ApprovalRequestsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show update]

  def index
    list_approvals
  end

  def edit
  end

  def show
  end

  def update
    current_action = permitted_attributes(ApprovalRequest).fetch("current_action", nil)
    @approval_request.assign_attributes(
      permitted_attributes(ApprovalRequest).merge(status: assign_status(current_action), last_action: current_action)
    )
    provider_action_successful = process_provider_action(current_action)
    @message = create_message
    list_approvals
    respond_to do |format|
      if @approval_request.save && Message::Create.call(@message) && provider_action_successful
        respond_with_success(format)
      else
        respond_with_error(format)
      end
    end
  end

  private

  def find_and_authorize
    @approval_request = authorize(ApprovalRequest.includes(:messages).find(params[:id]))
  end

  def list_approvals
    @approval_requests = ApprovalRequest.active.order(created_at: :desc)
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
    format.turbo_stream { flash.now[:notice] = notice }
    format.html { redirect_to backoffice_providers_path(notice: notice) }
  end

  def respond_with_error(format)
    alert = _("Message not sent")
    flash.now[:alert] = alert
    format.json { render :edit, status: :unprocessable_entity }
    format.html { render :show, status: :unprocessable_entity, alert: alert }
  end
end
