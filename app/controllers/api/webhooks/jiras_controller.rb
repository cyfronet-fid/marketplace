# frozen_string_literal: true

class Api::Webhooks::JirasController < ActionController::API
  # before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  class WebhookNotAuthorized < StandardError ; end

  rescue_from(ActiveRecord::RecordNotFound) do
    render json: { message: "No correlating order found" }
  end

  rescue_from(WebhookNotAuthorized) do
    render json: { message: "Secret does not match" }, status: :bad_request
  end

  before_action :authenticate_jira!

  def initialize
    @jira_client = Jira::Client.new
  end

  def authenticate_jira!
    raise WebhookNotAuthorized.new unless request.filtered_parameters.fetch("secret", "") == @jira_client.webhook_secret
  end

  def create
    issue_id = request.filtered_parameters["issue"]["id"]

    order = Order.find_by!(issue_id: issue_id)

    request.filtered_parameters["changelog"].fetch("items", []).each do |change|
      if change["field"] == "status"
        case change["to"].to_i
        when @jira_client.wf_todo_id
          status = Order::STATUSES[:registered]
        when @jira_client.wf_in_progress_id
          status = Order::STATUSES[:in_progress]
        when @jira_client.wf_done_id
          status = Order::STATUSES[:ready]
        else
          # :TODO, error, log, or do something to signalise that an unknown issue state has ocurred
          return render json: { message: "Unknown issue status (#{change["to"]})" }
        end

        order.new_change(status: status, message: "Order Changed")
        OrderMailer.changed(order).deliver_later
      end
    end

    render json: { message: "Updated" }
  end
end
