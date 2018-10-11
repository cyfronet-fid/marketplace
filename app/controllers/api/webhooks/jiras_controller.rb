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
    order = Order.find_by(issue_id: params["issue"]["id"])

    if order
      case params["webhookEvent"]
      when "jira:issue_updated"
        Jira::IssueUpdated.new(order, params["changelog"]).call
      else
        logger.warn("Webhook event not supported: #{params["webhookEvent"]}")
      end

    end
    render json: { message: "Updated" }
  end

  private

    def jira_client
      @jira_client ||= Jira::Client.new
    end

    def valid_jira_request?
      params.fetch("secret", "") == jira_client.webhook_secret
    end
end
