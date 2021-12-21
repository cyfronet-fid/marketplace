# frozen_string_literal: true

class Api::Webhooks::JirasController < ActionController::API
  class WebhookNotAuthorized < StandardError
  end

  rescue_from(WebhookNotAuthorized) { render json: { message: "Secret does not match" }, status: :bad_request }

  before_action :authenticate_jira!

  def authenticate_jira!
    raise WebhookNotAuthorized unless valid_jira_request?
  end

  def create
    element_updated = find_jira_item(ProjectItem) || find_jira_item(Project)

    if element_updated
      case params["webhookEvent"]
      when "jira:issue_updated"
        Jira::IssueUpdated.new(element_updated, params["changelog"]).call
      when "comment_created", "comment_updated"
        Jira::CommentActivity.new(element_updated, params["comment"]).call
      else
        logger.warn("Webhook event not supported: #{params["webhookEvent"]}")
      end
    end
    render json: { message: "Updated" }
  end

  private

  def find_jira_item(clazz)
    clazz.where.not(issue_id: nil).find_by(issue_id: params["issue_id"])
  end

  def valid_jira_request?
    params.fetch("secret", "") == jira_client.webhook_secret
  end

  def jira_client
    @jira_client ||= Jira::Client.new
  end
end
