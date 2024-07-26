# frozen_string_literal: true

class Probes::Create
  def initialize(cookies, params, current_user)
    @cookies = cookies
    @params = params
    @current_user = current_user
  end

  def call
    # Set unique client id per device per system
    @cookies.permanent[:client_uid] = SecureRandom.uuid if @cookies[:client_uid].nil?

    return if Mp::Application.config.recommender_host.nil?

    request_body = {
      timestamp: @params[:timestamp],
      source: JSON.parse(@params[:source].to_json),
      target: JSON.parse(@params[:target].to_json),
      action: JSON.parse(@params[:user_action].to_json),
      client_id: "marketplace"
    }

    request_body[:user_id] = @current_user.id unless @current_user.nil?

    request_body[:unique_id] = @cookies[:client_uid]

    unless request_body[:source]["root"]["service_id"].nil?
      request_body[:source]["root"]["service_id"] = request_body[:source]["root"]["service_id"].to_i
    end

    request_body[:source]["root"]["panel_id"] = "v1" if config.is_recommendation_panel

    Probes::ProbesJob.perform_later(request_body.to_json)
  end
end
