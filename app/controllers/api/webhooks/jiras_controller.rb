# frozen_string_literal: true

class Api::Webhooks::JirasController < ActionController::API
  class WebhookNotAuthorized < StandardError ; end

  rescue_from(WebhookNotAuthorized) do
    render json: { message: "Secret does not match" }, status: :bad_request
  end

  before_action :authenticate_jira!

  def authenticate_jira!
    raise WebhookNotAuthorized.new unless valid_jira_request?
  end

  def create
    project_item = ProjectItem.where.not(issue_id: nil).
            find_by(issue_id: params["issue_id"])
    if project_item
      case params["webhookEvent"]
      when "jira:issue_updated"
        Jira::IssueUpdated.new(project_item, params["changelog"]).call
      when "comment_created"
        Jira::CommentCreated.new(project_item, params["comment"]).call
      else
        logger.warn("Webhook event not supported: #{params["webhookEvent"]}")
      end

    end
    render json: { message: "Updated" }
  end

  private

    def valid_jira_request?
      params.fetch("secret", "") == jira_client.webhook_secret
    end

    def jira_client
      @jira_client ||= Jira::Client.new
    end
end
