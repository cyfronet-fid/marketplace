# frozen_string_literal: true

require "net/http"

module Service::Recommendable
  extend ActiveSupport::Concern
  include ValidationHelper

  ALLOWED_SEARCH_DATA_FIELDS = %i[
    scientific_domains
    providers
    sort
    q
    order_type
    rating
    related_platforms
    target_users
    geographical_availabilities
    category_id
  ].freeze

  @filter_param_transformers = {
    geographical_availabilities: ->(name) { Country.convert_to_regions_add_country(name) },
    scientific_domains: lambda { |ids|
                          if ids.instance_of?(Array)
                            ids.map(&:to_i) + ids.map { |id| ScientificDomain.find(id).descendant_ids }.flatten
                          else
                            ids.first.to_i
                          end
                        },
    category_id: ->(slug) { [Category.find_by(slug: slug).id] + Category.find_by(slug: slug).descendant_ids },
    providers: ->(ids) { ids.instance_of?(Array) ? ids.map(&:to_i) : ids.first.to_i },
    related_platforms: ->(ids) { ids.instance_of?(Array) ? ids.map(&:to_i) : ids.first.to_i },
    target_users: ->(ids) { ids.instance_of?(Array) ? ids.map(&:to_i) : ids.first.to_i }
  }
  @filter_key_transformers = {
    category_id: "categories"
  }

  included do
    before_action only: :index do
      @params = params
    end
  end

  def fetch_recommended
    # Set unique client id per device per system
    client_uid = cookies[:client_uid]
    if client_uid.nil? || !validate_uuid_format(client_uid)
      cookies[:client_uid] = { value: SecureRandom.uuid, expires: 1.week.from_now }
    end

    size = get_services_size_by(ab_test(:recommendation_panel))
    if Mp::Application.config.recommender_host.nil?
      return Rails.env.production? ? [] : Recommender::SimpleRecommender.new.call(size)
    end

    get_recommended_services_by(service_search_state, size)
  end

  private

  def get_recommended_services_by(body, size)
    url = "#{Mp::Application.config.recommender_host}/recommendations"
    response = Faraday.post(url, body.to_json, { "Content-Type": "application/json", Accept: "application/json" })
    ids = JSON.parse(response.body)["recommendations"]
    services = Service.where(id: ids, status: %i[published unverified]).sort_by { |s| ids.index(s.id) }.take(size)

    if services.size == size
      services
    else
      []
    end
  rescue StandardError
    Sentry.capture_message("Recommendation service, recommendation endpoint response error")
    []
  end

  def service_search_state
    service_search_state = {
      timestamp: Date.now.strftime("%Y-%m-%dT%H:%M:%S.%L%z"),
      unique_id: cookies[:client_uid],
      visit_id: cookies[:targetId],
      page_id: "/service",
      panel_id: ab_test(:recommendation_panel),
      search_data: get_filters_by(@params)
    }

    service_search_state[:user_id] = current_user.id unless current_user.nil?

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
    params&.each do |key, value|
      next if ALLOWED_SEARCH_DATA_FIELDS.exclude?(key.to_sym) || value.blank?

      filter_name = key.sub "-filter", ""
      filters[filter_name] = value
      if @filter_param_transformers.key? filter_name.to_sym
        filters[filter_name] = @filter_param_transformers[filter_name.to_sym].call value
      end

      if @filter_key_transformers.key? filter_name.to_sym
        filters[@filter_key_transformers[filter_name.to_sym]] = filters.delete filter_name
      end
    end
    filters
  end
end
