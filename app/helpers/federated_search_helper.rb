# frozen_string_literal: true

module FederatedSearchHelper
  FILTER_CONFIGS = {
    scientific_domains: {
      model: ScientificDomain,
      label: "Scientific Domain"
    },
    providers: {
      model: Provider,
      label: "Provider"
    },
    target_users: {
      model: TargetUser,
      label: "Target User"
    },
    platforms: {
      model: Platform,
      label: "Platform"
    },
    research_activities: {
      model: Vocabulary::MarketplaceLocation,
      label: "Marketplace Location"
    }
  }.freeze

  SIMPLE_FILTERS = {
    rating: {
      label: "Rating",
      value_mapping: {
        "5" => "5 stars",
        "4" => "4+ stars",
        "3" => "3+ stars",
        "2" => "2+ stars",
        "1" => "1+ stars"
      }
    },
    order_type: {
      label: "Order Type",
      value_mapping: {
        "open_access" => "Open Access",
        "fully_open_access" => "Fully Open Access",
        "other" => "Other"
      }
    }
  }.freeze

  def active_filters?
    (FILTER_CONFIGS.keys + SIMPLE_FILTERS.keys + [:nodes]).any? { |filter| params[filter].present? }
  end

  def active_filters
    filters = []

    # Handle model-based filters
    FILTER_CONFIGS.each { |filter_type, config| filters.concat(build_model_filters(filter_type, config)) }

    # Handle simple filters
    SIMPLE_FILTERS.each { |filter_type, config| filters.concat(build_simple_filters(filter_type, config)) }

    # Handle nodes filter
    filters.concat(build_nodes_filters) if params[:nodes].present?

    filters
  end

  def remove_filter_url(filter_type, filter_value)
    current_params = params.to_unsafe_h.except(:controller, :action)

    if FILTER_CONFIGS.key?(filter_type)
      remove_model_filter(current_params, filter_type, filter_value)
    elsif filter_type == :nodes
      remove_nodes_filter(current_params, filter_value)
    else
      current_params.delete(filter_type)
    end

    federation_services_path(current_params)
  end

  # Helper do sanityzacji ID dla HTML
  def sanitize_for_id(text)
    text.to_s.gsub(/[^a-zA-Z0-9_-]/, "_").squeeze("_")
  end

  def query_params
    session[:query] || params.slice(:q, :sort, :per_page)
  end

  def service_highlight(service, field, highlights)
    service_id = service["slug"] || service["id"]
    service_highlights = highlights[service_id]

    return service[field] unless service_highlights && service_highlights[field]

    highlighted_text = service_highlights[field] || service[field]
    highlighted_text.html_safe
  end

  def highlights?(service, highlights)
    service_id = service["pid"] || service["id"]
    service_highlights = highlights[service_id.to_i] || highlights[service_id.to_s]
    service_highlights.present? && service_highlights.values.any?(&:present?)
  end

  private

  def build_model_filters(filter_type, config)
    return [] unless params[filter_type].present?

    eids = normalize_to_array(params[filter_type])
    records = config[:model].where(eid: eids)

    records.map do |record|
      {
        name: "#{config[:label]}: #{record.name}",
        type: filter_type,
        value: record.eid,
        remove_url: remove_filter_url(filter_type, record.eid)
      }
    end
  end

  def build_simple_filters(filter_type, config)
    return [] unless params[filter_type].present?

    value = params[filter_type]
    display_value = config[:value_mapping][value] || value.humanize

    [
      {
        name: "#{config[:label]}: #{display_value}",
        type: filter_type,
        value: value,
        remove_url: remove_filter_url(filter_type, value)
      }
    ]
  end

  def build_nodes_filters
    return [] unless params[:nodes].present?

    node_names = normalize_to_array(params[:nodes])

    node_names.map do |node_name|
      { name: "Node: #{node_name}", type: :nodes, value: node_name, remove_url: remove_filter_url(:nodes, node_name) }
    end
  end

  def remove_model_filter(current_params, filter_type, filter_value)
    return unless current_params[filter_type].present?

    if current_params[filter_type].is_a?(Array)
      current_params[filter_type] = current_params[filter_type].reject { |v| v == filter_value }
      current_params.delete(filter_type) if current_params[filter_type].empty?
    elsif current_params[filter_type] == filter_value
      current_params.delete(filter_type)
    end
  end

  def remove_nodes_filter(current_params, filter_value)
    return unless current_params[:nodes].present?

    if current_params[:nodes].is_a?(Array)
      current_params[:nodes] = current_params[:nodes].reject { |v| v == filter_value }
      current_params.delete(:nodes) if current_params[:nodes].empty?
    elsif current_params[:nodes] == filter_value
      current_params.delete(:nodes)
    end
  end

  def normalize_to_array(value)
    value.is_a?(Array) ? value : [value]
  end
end
