# frozen_string_literal: true

require "net/http"

module Service::Recommendable
  extend ActiveSupport::Concern

  included do
    before_action only: :index do
      @params = params
    end
  end

  def fetch_recommended
    # Set unique client id per device per system
    if cookies[:client_uid].nil?
      cookies.permanent[:client_uid] = SecureRandom.hex(10) + "." + Time.now.getutc.to_i.to_s
    end

    size = get_services_size_by(ab_test(:recommendation_panel))
    if Mp::Application.config.recommender_host.nil?
      return Recommender::SimpleRecommender.new.call size
    end

    get_recommended_services_by(get_service_search_state, size)
  end

  private
    def get_recommended_services_by(body, size)
      url = Mp::Application.config.recommender_host + "/recommendations"
      response = Unirest.post(url, { "Content-Type" => "application/json" }, body.to_json)
      if response.nil? || response[:recommendations].nil? || response[:recommendations].length == 0
        Raven.capture_message("Recommendation service, recommendation endpoint response error")
        return Recommender::SimpleRecommender.new.call(size)
      end

      Service.where(id: response[:recommendations].take(size))
      rescue
        Raven.capture_message("Recommendation service, recommendation endpoint response error")
        Recommender::SimpleRecommender.new.call(size)
    end

    def get_service_search_state
      service_search_state = {
        "timestamp": Time.now.getutc.to_i.to_s,
        "unique_id": cookies[:client_uid],
        "visit_id": cookies[:client_uid] + "." + Time.now.getutc.to_i.to_s,
        "page_id": "/service",
        "panel_id": ab_test(:recommendation_panel)
      }

      unless session[:query].nil? || session[:query][:q].nil?
        service_search_state[:search_phrase] = session[:query][:q]
      end

      unless @active_filters.nil?
        service_search_state[:filters] = get_filters_by(@params)
      end

      service_search_state["logged_user"] = false
      unless current_user.nil?
        service_search_state["user_id"] = current_user.id
        service_search_state["logged_user"] = true
      end

      service_search_state
    end

    def get_services_size_by(ab_test_version)
      case ab_test_version
      when "v1"
        3
      when "v2"
        2
      else
        3
      end
    end

    def get_filters_by(params)
      filters = {}
      unless params.nil?
        params.each do |key, value|
          next if key == "controller" || key == "action"

          if key.match?(/[a-z_]_id/)
            if key == "category_id"
              filters[key] = Category.find_by(slug: value)[:id]
              next
            end
          end

          if key.match?(/[a-z_]-filter/)
            key = key.sub "-filter", ""
            value = params[key]

            next if value.nil? || value == "" || value == []
            filters[key] = value
            next
          end

          next if value.nil? || value == "" || value == []
          if !key.match?(/[a-z_]-filter/) && !key.match?(/[a-z_]-all/)
            filters[key] = value
          end
        end
      end
      filters
    end
end
