# frozen_string_literal: true

class Federation::ServicesController < ApplicationController
  include Service::Searchable
  layout "clear"

  # Avoid initializing local search filters on the federation page to prevent ES queries with external EIDs
  skip_before_action :initialize_filters, only: :index

  helper_method :active_filters, :active_filters?

  RESULTS_PER_PAGE = 10

  # rubocop:disable Metrics/AbcSize
  def index
    api_base_url = Mp::Application.config.federation_api_base_url
    @aggregator_type = Mp::Application.config.aggregator_type

    unless api_base_url.present?
      @json_data = { error: "Federation API not configured" }
      return respond_to_format
    end

    api_url = @aggregator_type == "mp" ? build_api_url(api_base_url) : build_api_url_pc(api_base_url)

    begin
      uri = URI(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      if http.use_ssl?
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        # Clear CRL check flag if it's enabled by default in the environment
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
        if defined?(OpenSSL::X509::V_FLAG_CRL_CHECK)
          http.cert_store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK & ~OpenSSL::X509::V_FLAG_CRL_CHECK
        end
      end
      http.read_timeout = 10
      http.open_timeout = 5

      request_uri = uri.request_uri
      response = http.get(request_uri)

      case response.code
      when "200"
        if @aggregator_type == "mp"
          @json_data = JSON.parse(response.body)
          # Extract highlights from JSON response
          @highlights = @json_data["highlights"]
          # Extract nodes information for filtering
          @available_nodes = extract_available_nodes
          load_filter_options
        elsif @aggregator_type == "pc"
          begin
            json_response = JSON.parse(response.body)
            unless json_response.is_a?(Hash)
              Rails.logger.error "Federation API returned unexpected format. Expected Hash, got #{json_response.class}"
              @json_data = { error: "Unexpected response format" }
              return respond_to_format
            end
            @json_data = map_federation_response(json_response)
            # Extract highlights from JSON response
            @highlights = @json_data["highlights"] || {}
            # Extract nodes information for filtering
            @available_nodes = extract_available_nodes_pc
            load_filter_options
          rescue StandardError => e
            Rails.logger.error "ERROR in mapping: #{e.class} - #{e.message}\n#{e.backtrace[0..5].join("\n")}"
            @json_data = { error: "API Mapping Failed" }
          end
        end
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

  def build_facet_map(json, field)
    facet = json["facets"]&.find { |f| f["field"] == field }
    facet_values = facet ? facet["values"] : []
    facet_values.to_h { |v| [v["value"], v["label"]] }
  end

  def map_results(json)
    scientific_domain_map = build_facet_map(json, "scientific_domains")
    service_providers_map = build_facet_map(json, "service_providers")
    nodes_map = build_facet_map(json, "node")

    Array(json["results"]).map do |item|
      service = item.dig("result", "service") || {}
      domains = Array(service["scientificDomains"])
      providers = Array(service["serviceProviders"])

      {
        "pid" => item["result"]["id"],
        "name" => item["result"]["service"]["name"],
        "slug" => item["id"],
        # "tagline" => item["tagline"],
        "description" => item["result"]["service"]["description"],
        # "rating" => nil,
        "score" => item["score"],
        "path" => item["webpage"],
        "logo" => item["result"]["service"]["logo"],
        "scientific_domains" =>
          domains.map do |domain|
            value = domain["scientificDomain"].to_s
            { "name" => scientific_domain_map.fetch(value, value) }
          end,
        "target_users" => Array(item["targetUsers"]).map { |u| { "name" => u.to_s } },
        "platforms" => Array(item["relatedPlatforms"]).map { |p| { "name" => p } },
        "resource_organisation" => {
          "name" => item["resourceOrganisation"],
          "pid" => item["resourceOrganisation"]
        },
        "providers" => providers.map { |provider| { "name" => service_providers_map.fetch(provider, provider) } },
        "webpage" => item["webpage"] || item["userManual"] || item["order"],
        "nodePID" => nodes_map.fetch(item["result"]["service"]["nodePID"], item["result"]["service"]["nodePID"])
        # "source_node_url" => "test node pid"
      }
    end
  end

  def map_federation_response(json)
    results = map_results(json)

    total_count = json["total"].to_i
    total_pages = (total_count.to_f / RESULTS_PER_PAGE).ceil

    facets_array = json["facets"].is_a?(Array) ? json["facets"] : []
    metadata = json["metadata"].is_a?(Hash) ? json["metadata"] : {}
    nodes = metadata["nodes"].is_a?(Array) ? metadata["nodes"] : []
    node_urls = create_url_dict(nodes)

    mapped_facets = {}
    facets_labels = {}
    facets_to_skip = %w[
      access_policy
      description
      terms_of_use
      tags
      node
      resource_owner
      urls
      type
      privacy_policy
      name
      logo
      order_link
      alternative_pids
      webpage
      contacts
    ]
    facets_array.each do |facet|
      field = facet["field"].to_s
      next if facets_to_skip.include?(field)

      values = Array(facet["values"]).map { |v| map_facet_value_pc(v) }

      values = values.sort_by { |v| v["name"].to_s[/^\d+/].to_i }.reverse if field == "trl"

      mapped_facets[field] = values
      facets_labels[field] = facet["label"].to_s
    end

    group_pc_facets(mapped_facets, facets_labels)

    node_facets = facets_array.find { |f| f["field"] == "node" }
    node_facets_values = Array(node_facets&.dig("values")).map { |v| map_facet_value_pc(v) }

    current_page = [params[:page].to_i, 1].max
    {
      "status" => "success",
      "results" => results,
      "pagination" => {
        "current_page" => current_page,
        "per_page" => RESULTS_PER_PAGE,
        "total_count" => total_count,
        "total_pages" => total_pages,
        "has_next_page" => current_page < total_pages,
        "has_prev_page" => current_page > 1
      },
      "facets" => mapped_facets,
      "facets_labels" => facets_labels,
      "node_facets" => node_facets_values,
      "node_urls" => node_urls
    }
  end

  def create_url_dict(node_dict)
    node_dict.each_with_object({}) do |node, hash|
      capability = node["capabilities"].find { |c| c["capability_type"] == "Front Office" }
      hash[node["name"]] = capability&.dig("endpoint")
    end
  end

  def extract_available_nodes
    return [] unless @json_data && @json_data["nodes"]

    @json_data["nodes"].map { |node| { name: node["name"], value: node["name"], url: node["url"] } }
  end

  def extract_available_nodes_pc
    node_facets = @json_data["node_facets"] || []
    node_facets.map { |node| { name: node["name"], value: node["eid"], url: node["eid"] } }
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

  def build_api_url_pc(base_url)
    clean_base_url = base_url.to_s.strip.chomp("/")
    uri = URI.parse(clean_base_url)
    raise URI::InvalidURIError unless %w[http https].include?(uri.scheme)

    api_params = {}

    page = [params[:page].to_i, 1].max
    api_params[:quantity] = RESULTS_PER_PAGE
    api_params[:from] = (page - 1) * RESULTS_PER_PAGE
    api_params[:keyword] = params[:q] if params[:q].present?

    if params[:nodes].present?
      nodes_str = "[#{Array(params[:nodes]).join(",")}]"
      api_params[:node] = nodes_str
    end

    reserved_keys = %w[q page nodes controller action]
    params.to_unsafe_h.each do |key, val|
      next if reserved_keys.include?(key.to_s)
      next unless val.present?
      # next if val == "true" # could be a naive solution for unwanted true value in parameters

      values = Array(val).map(&:to_s).reject(&:blank?)
      api_params[key] = "[#{values.join(",")}]" if values.present?
    end
    uri.query = api_params.to_query if api_params.present?
    uri.to_s
  rescue URI::InvalidURIError => e
    Rails.logger.error "Invalid federation API base URL: #{base_url}. Message: #{e.message}"
    raise StandardError, "Invalid API configuration"
  end

  def load_filter_options
    # Build @facets hash for the view from API JSON instead of loading from DB
    @facets = @json_data && @json_data["facets"]
    @facets_labels = @json_data&.dig("facets_labels") || {}
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def active_filters
    filters = []

    # Build filters from params using @facets (API-provided options)
    if @facets.present?
      facet_param_names = (@facets.keys.map(&:to_s) + %w[scientific_subdomains subcategories supercategories]).uniq

      # Determine all selected EIDs across the board for path intersection
      all_selected_eids = facet_param_names.flat_map { |p| Array(params[p]).map(&:to_s) }

      facet_param_names.each do |param_name|
        next unless params[param_name].present?

        selected_eids = Array(params[param_name]).map(&:to_s)

        selected_eids.each do |eid|
          # Must search across all facets to find the option
          opt = nil
          parent_tree_name = nil

          @facets.each do |tree_name, options_tree|
            opt = find_option_in_facets(options_tree, eid)
            if opt
              parent_tree_name = tree_name
              break
            end
          end

          next unless opt

          path = path_to_eid(@facets[parent_tree_name], eid)
          next if path && path[0..-2].intersect?(all_selected_eids)

          label = opt["name"] || eid
          filters << { name: "#{param_name.to_s.humanize}: #{label}", remove_url: remove_filter_url(param_name, eid) }
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
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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

    if @aggregator_type == "pc"
      selected_nodes = @available_nodes.select { |node| param_values.include?(node[:value]) }
      selected_nodes.map do |node|
        { name: "Node: #{node[:name]}", remove_url: remove_filter_url("nodes", node[:value]) }
      end
    else
      selected_nodes = @available_nodes.select { |node| param_values.include?(node[:name]) }
      selected_nodes.map do |node|
        { name: "Node: #{node[:name]}", remove_url: remove_filter_url("nodes", node[:name]) }
      end
    end
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
    facet_keys = ((@facets || {}).keys.map(&:to_s) + %w[scientific_subdomains subcategories supercategories]).uniq
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

  def map_facet_value_pc(val)
    name = val["label"].present? ? val["label"].to_s : val["value"].to_s
    mapped = { "eid" => val["value"].to_s, "name" => name }
    mapped["count"] = val["count"] if val.key?("count")
    mapped["children"] = (
      if val["children"].present?
        Array(val["children"]).map { |child| map_facet_value_pc(child) }
      else
        []
      end
    )
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

  def group_pc_facets(mapped_facets, facets_labels)
    nest_pc_facets(
      mapped_facets,
      "scientific_domains",
      "scientific_subdomains",
      "scientific_domain",
      "scientific_subdomain"
    )
    facets_labels.delete("scientific_subdomains")
    nest_pc_facets(mapped_facets, "categories", "subcategories", "category", "subcategory")
    facets_labels.delete("subcategories")
    nest_pc_facets(mapped_facets, "supercategories", "categories", "supercategory", "category")

    if mapped_facets.key?("supercategories")
      mapped_facets["categories"] = mapped_facets.delete("supercategories")
      facets_labels["categories"] = facets_labels.delete("supercategories") || "Categories"
    end
  end

  def nest_pc_facets(mapped_facets, parent_key, child_key, parent_prefix, child_prefix)
    return unless mapped_facets[parent_key] && mapped_facets[child_key]

    parents = mapped_facets[parent_key]
    children = mapped_facets.delete(child_key)

    children.each do |child|
      child_eid = child["eid"].to_s
      child_suffix = child_eid.sub("#{child_prefix}-", "")

      parent =
        parents.find do |p|
          p_suffix = p["eid"].to_s.sub("#{parent_prefix}-", "")
          child_suffix.start_with?("#{p_suffix}-") || child_suffix == p_suffix
        end

      if parent
        parent["children"] ||= []
        parent["children"] << child
      else
        parents << child
      end
    end
  end
end
