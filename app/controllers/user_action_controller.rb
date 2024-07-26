# frozen_string_literal: true

class UserActionController < ApplicationController
  # Store user action in recommendation system
  def create
    return if Mp::Application.config.recommender_host.nil?

    request_body = {
      timestamp: Time.now.utc.iso8601,
      source: JSON.parse(params[:source].to_json),
      target: JSON.parse(params[:target].to_json),
      action: JSON.parse(params[:user_action].to_json),
      client_id: "marketplace"
    }

    request_body[:user_id] = current_user.id unless current_user.nil?

    request_body[:unique_id] = cookies[:client_uid]

    unless request_body[:source]["root"]["service_id"].nil?
      request_body[:source]["root"]["service_id"] = request_body[:source]["root"]["service_id"].to_i
    end

    request_body[:source]["root"]["panel_id"] = "v1" if config.is_recommendation_panel

    # We publish user actions to both JMS under the "user_actions" topic
    # as well as to the recommender_lib server directly for now

    if %w[all recommender_lib].include? Mp::Application.config.user_actions_target
      Probes::ProbesJob.perform_later(request_body.to_json)
    end

    if %w[all jms].include? Mp::Application.config.user_actions_target
      Jms::PublishJob.perform_later(request_body.to_json, :user_actions)
    end
  end
end
