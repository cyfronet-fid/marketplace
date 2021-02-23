# frozen_string_literal: true

class UserActionController < ApplicationController
  # Store user action in recommendation system
  def create
    # Set unique client id per device per system
    if cookies[:client_uid].nil?
      cookies.permanent[:client_uid] = SecureRandom.hex(10) + "." + Time.now.getutc.to_i.to_s
    end

    if Mp::Application.config.recommender_host.nil?
      return
    end

    request_body = {
      timestamp: params[:timestamp],
      source: JSON.parse(params[:source].to_json),
      target: JSON.parse(params[:target].to_json),
      action: JSON.parse(params[:action].to_json)
    }

    puts request_body.inspect

    unless current_user.nil?
      request_body[:logged_user] = true
      request_body[:user_id] = current_user.id
    end

    request_body[:unique_id] = cookies[:client_uid]
    request_body[:source]["visit_id"] += "." + cookies[:client_uid]
    request_body[:target]["visit_id"] += "." + cookies[:client_uid]

    is_recommendation_panel = params[:source]["root"]["type"] != "other"
    if is_recommendation_panel
      request_body[:source]["root"]["panel_id"] = ab_test(:recommendation_panel)
    end


    url = Mp::Application.config.recommender_host + "/user_actions"
    Probes::ProbesJob.perform_later url, request_body.to_json
  end
end
