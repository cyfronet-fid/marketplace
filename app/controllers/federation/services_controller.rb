# frozen_string_literal: true

class Federation::ServicesController < ApplicationController
  include Service::Searchable
  layout "clear"

  # Avoid initializing local search filters on the federation page to prevent ES queries with external EIDs
  skip_before_action :initialize_filters, only: :index

  helper_method :active_filters, :active_filters?

  # rubocop:disable Metrics/AbcSize
  def index
    api_base_url = Mp::Application.config.federation_api_base_url

    unless api_base_url.present?
      @json_data = { error: "Federation API not configured" }
      return respond_to_format
    end

    api_url = build_api_url(api_base_url)

    begin
      uri = URI(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = 10
      http.open_timeout = 5

      request_uri = uri.request_uri
      response = http.get(request_uri)

      case response.code
      when "200"
        @json_data = JSON.parse(response.body)
        # Extract highlights from JSON response
        @highlights = @json_data["highlights"]
        # Extract nodes information for filtering
        @available_nodes = extract_available_nodes
        load_filter_options
      when "404"
        @json_data = { error: "Federation API endpoint not found" }
      when "500", "502", "503", "504"
        Rails.logger.error "Federation API server error: #{response.code} - #{response.message}"
        @json_data = { error: "Federation API server error" }
      else
        Rails.logger.error "Federation API returned #{response.code}: #{response.message}"
        @json_data = { error: "API returned #{response.code}: #{response.message}" }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Federation API JSON parse error: #{e.message}"
      @json_data = { error: "Invalid API response format" }
    rescue Net::ReadTimeout => e
      Rails.logger.error "Federation API read timeout: #{e.message}"
      @json_data = { error: "API request timed out" }
    rescue Net::OpenTimeout => e
      Rails.logger.error "Federation API open timeout: #{e.message}"
      @json_data = { error: "Connection timeout" }
    rescue OpenSSL::SSL::SSLError => e
      Rails.logger.error "Federation API SSL error: #{e.message}"
      @json_data = { error: "SSL connection failed" }
    rescue SocketError => e
      Rails.logger.error "Federation API connection error: #{e.message}"
      @json_data = { error: "Cannot connect to Federation API" }
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "Federation API connection refused: #{e.message}"
      @json_data = { error: "Cannot connect to Federation API" }
    rescue StandardError => e
      Rails.logger.error "Federation API request failed: #{e.class}: #{e.message}"
      @json_data = { error: "Failed to fetch data: #{e.message}" }
    end

    respond_to_format
  end

  # rubocop:enable Metrics/AbcSize

  private

  def extract_available_nodes
    return [] unless @json_data && @json_data["nodes"]

    @json_data["nodes"].map { |node| { name: node["name"], value: node["name"], url: node["url"] } }
  end

  def scope
    policy_scope(Service)
  end

  def respond_to_format
    respond_to do |format|
      format.html
      format.json { render json: @json_data }
    end
  end

  def build_api_url(base_url)
    clean_base_url = base_url.to_s.strip.chomp("/")
    uri = URI.parse(clean_base_url)
    raise URI::InvalidURIError unless %w[http https].include?(uri.scheme)
    query_string = request.query_string.present? ? "?#{request.query_string}" : ""
    "#{clean_base_url}#{query_string}"
  rescue URI::InvalidURIError => e
    Rails.logger.error "Invalid federation API base URL: #{base_url}. Message: #{e.message}"
    raise StandardError, "Invalid API configuration"
  end

  def load_filter_options
    # Build @facets hash for the view from API JSON instead of loading from DB
    @facets = @json_data && @json_data["facets"]
  end

  def active_filters
    filters = []

    # Build filters from params using @facets (API-provided options)
    if @facets.present?
      @facets.each_key do |param_name|
        next unless params[param_name].present?

        selected_eids = Array(params[param_name]).map(&:to_s)

        selected_eids.each do |eid|
          path = path_to_eid(@facets[param_name], eid)
          next if path && path[0..-2].intersect?(selected_eids)

          if (opt = find_option_in_facets(@facets[param_name], eid))
            label = opt["name"] || eid
            filters << { name: "#{param_name.to_s.humanize}: #{label}", remove_url: remove_filter_url(param_name, eid) }
          end
        end
      end
    end

    # Nodes filter from header
    filters.concat(build_nodes_filter_items) if params[:nodes].present?

    # Keep rating simple filter handling
    if params[:rating].present?
      filters << { name: "Rating: #{params[:rating]}+", remove_url: remove_filter_url("rating") }
    end

    filters.flatten
  end

  # Recursively search options tree for an eid
  def find_option_in_facets(options, eid)
    options.each do |opt|
      return opt if opt["eid"].to_s == eid.to_s
      children = opt["children"]
      if children.present?
        found = find_option_in_facets(children, eid)
        return found if found
      end
    end
    nil
  end

  def build_nodes_filter_items
    return [] unless @available_nodes.present?

    param_values = Array(params[:nodes])
    selected_nodes = @available_nodes.select { |node| param_values.include?(node[:name]) }

    selected_nodes.map { |node| { name: "Node: #{node[:name]}", remove_url: remove_filter_url("nodes", node[:name]) } }
  end

  def remove_filter_url(param_name, value = nil)
    new_params = params.to_unsafe_h.dup

    if value
      current_values = Array(new_params[param_name])
      new_values = current_values.reject { |v| v == value }
      if new_values.empty?
        new_params.delete(param_name)
      else
        new_params[param_name] = new_values
      end
    else
      new_params.delete(param_name)
    end

    federation_services_path(new_params.except(:controller, :action))
  end

  def active_filters?
    facet_keys = (@facets || {}).keys.map(&:to_s)
    (facet_keys + %w[rating nodes]).any? { |key| params[key].present? }
  end

  def build_facets_hash(raw_facets)
    return {} unless raw_facets.is_a?(Array)

    raw_facets.each_with_object({}) do |facet, acc|
      field = facet.to_s
      values = Array(facet["values"]).map { |v| map_facet_value(v) }
      acc[field] = values
    end
  end

  def map_facet_value(val)
    mapped = { "eid" => val["value"].to_s, "name" => val["label"].to_s }
    mapped["count"] = val["count"] if val.key?("count")
    mapped["children"] = Array(val["children"]).map { |child| map_facet_value(child) } if val["children"].present?
    mapped
  end

  # Returns array of eids from root to the target eid within the given options tree
  # Example: ["parent_eid", "child_eid", "target_eid"]
  def path_to_eid(options, target_eid, path = [])
    target_eid = target_eid.to_s
    options.each do |opt|
      current_eid = opt["eid"].to_s
      new_path = path + [current_eid]
      return new_path if current_eid == target_eid

      children = opt["children"]
      if children.present?
        found = path_to_eid(children, target_eid, new_path)
        return found if found
      end
    end
    nil
  end
end
