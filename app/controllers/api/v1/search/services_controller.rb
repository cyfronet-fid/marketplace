# frozen_string_literal: true

class Api::V1::Search::ServicesController < Api::V1::Search::ApplicationController
  include Service::Sortable

  def index
    params[:sort] = "_score" if params[:sort].blank?
    @services =
      Service.search(
        params[:q] || "*",
        **common_params,
        where: build_eid_constraints,
        page: params[:page] || 1,
        per_page: params[:per_page] || 25,
        order: ordering,
        highlight: {
          tag: "<mark>"
        },
        aggs: %i[categories scientific_domains providers platforms research_activities dedicated_for order_type rating],
        scope_results: ->(r) do
          r.includes(
            :resource_organisation,
            :categories,
            :platforms,
            :providers,
            :marketplace_locations,
            :scientific_domains,
            :target_users,
            :offers
          ).with_attached_logo
        end
      )

    @offers =
      Offer.search(
        params[:q] || "*",
        where: {
          service_id: @services.map(&:id)
        },
        load: false,
        fields: [:offer_name],
        operator: :or,
        match: :word_middle,
        highlight: {
          tag: "<mark>"
        }
      )

    render json: {
             results: serialize_services(@services),
             offers: serialize_offers(@offers),
             pagination: pagination_data(@services),
             highlights: highlights(@services),
             facets: facets(@services)
           }
  end

  private

  def scope
    policy_scope(Service)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def build_eid_constraints
    constraint = {}

    constraint[:id] = policy_scope(Service).ids.uniq

    if params[:scientific_domains].present?
      domain_eids =
        params[:scientific_domains].is_a?(Array) ? params[:scientific_domains] : [params[:scientific_domains]]
      scientific_domain_ids = ScientificDomain.where(eid: domain_eids).pluck(:id)
      constraint[:scientific_domains] = scientific_domain_ids if scientific_domain_ids.any?
    end

    if params[:providers].present?
      provider_eids = params[:providers].is_a?(Array) ? params[:providers] : [params[:providers]]
      provider_ids = Provider.where(pid: provider_eids).pluck(:id)
      constraint[:providers] = provider_ids if provider_ids.any?
    end

    if params[:target_users].present?
      target_user_eids = params[:target_users].is_a?(Array) ? params[:target_users] : [params[:target_users]]
      target_user_ids = TargetUser.where(eid: target_user_eids).pluck(:id)
      # ES index field for target users is `dedicated_for`, not `target_users`
      constraint[:dedicated_for] = target_user_ids if target_user_ids.any?
    end

    if params[:platforms].present?
      platform_eids = params[:platforms].is_a?(Array) ? params[:platforms] : [params[:platforms]]
      platform_ids = Platform.where(eid: platform_eids).pluck(:id)
      constraint[:platforms] = platform_ids if platform_ids.any?
    end

    if params[:research_activities].present?
      activity_eids =
        params[:research_activities].is_a?(Array) ? params[:research_activities] : [params[:research_activities]]
      activity_ids = Vocabulary::MarketplaceLocation.where(eid: activity_eids).pluck(:id)
      constraint[:research_activities] = activity_ids if activity_ids.any?
    end

    constraint[:rating] = params[:rating] if params[:rating].present?
    constraint[:order_type] = params[:order_type] if params[:order_type].present?

    constraint
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def serialize_services(services)
    scores_map = build_scores_map(services)

    ordered_ids = extract_ordered_ids_from_response(services)

    services_by_id = services.results.index_by(&:id)

    ordered_ids.filter_map do |service_id|
      service = services_by_id[service_id]
      next unless service

      Api::V1::Search::ServiceSerializer.new(service, score: scores_map[service_id]).as_json
    end
  end

  def extract_ordered_ids_from_response(services)
    return services.results.map(&:id) unless services.response&.dig("hits", "hits")

    services.response["hits"]["hits"].map { |hit| hit["_id"].to_i }
  end

  def serialize_offers(offers)
    offer_scores_map = build_offer_scores_map(offers)

    offers
      .with_highlights
      .group_by { |o, _| o.service_id }
      .to_h
      .transform_values do |service_offers|
        service_offers.map do |offer, highlights|
          Api::V1::Search::OfferSerializer.new(offer, score: offer_scores_map[offer.id], highlights: highlights).as_json
        end
      end
  end

  def build_scores_map(services)
    scores = {}

    services.results.each_with_index do |service, index|
      if services.response && services.response["hits"] && services.response["hits"]["hits"][index]
        scores[service.id] = services.response["hits"]["hits"][index]["_score"]
      elsif service.respond_to?(:_score)
        scores[service.id] = service._score
      elsif service.respond_to?(:elasticsearch_score)
        scores[service.id] = service.elasticsearch_score
      else
        scores[service.id] = services.results.with_hit.find { |hit| hit.id == service.id }&.hit&.dig("_score")
      end
    end

    scores
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def build_offer_scores_map(offers)
    scores = {}

    if offers.respond_to?(:results)
      offers.results.each_with_index do |offer, index|
        if offers.response && offers.response["hits"] && offers.response["hits"]["hits"][index]
          scores[offer.id] = offers.response["hits"]["hits"][index]["_score"]
        elsif offer.respond_to?(:_score)
          scores[offer.id] = offer._score
        elsif offer.respond_to?(:elasticsearch_score)
          scores[offer.id] = offer.elasticsearch_score
        else
          scores[offer.id] = offers.results.with_hit.find { |hit| hit.id == offer.id }&.hit&.dig("_score")
        end
      end
    else
      offers.each do |offer|
        if offer.respond_to?(:_score)
          scores[offer.id] = offer._score
        elsif offer.respond_to?(:elasticsearch_score)
          scores[offer.id] = offer.elasticsearch_score
        end
      end
    end

    scores
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def pagination_data(services)
    {
      current_page: services.current_page,
      total_pages: services.total_pages,
      total_count: services.total_count,
      per_page: services.limit_value
    }
  end

  def common_params
    {
      fields: %w[name^7 tagline^3 description offer_names provider_names resource_organisation_name],
      operator: "or",
      match: :word_middle
    }
  end

  def highlights(from_search)
    result = from_search.try(:with_highlights) || {} if (params[:q]&.size || 0) > 2
    return {} if result.blank?
    result.to_h.transform_keys(&:slug)
  end

  def load_root_categories!
    @root_categories = Category.roots.order(:name)
    @research_activities = Vocabulary::ResearchActivity.where.not(description: "")
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def facets(from_search)
    aggs = from_search.try(:aggregations) || {}

    # Helper to extract buckets in a resilient way (handles possible nested structure)
    extract_buckets =
      lambda do |aggs_hash, field|
        return [] if aggs_hash.blank?

        # Support both symbol and string keys returned by Searchkick/Elasticsearch
        field_sym = field.is_a?(String) ? field.to_sym : field
        field_str = field.to_s

        node = aggs_hash[field_sym] || aggs_hash[field_str]
        return [] unless node.is_a?(Hash)

        nested = node[field_sym] || node[field_str]
        if nested.is_a?(Hash) && nested["buckets"].is_a?(Array)
          nested["buckets"]
        elsif node["buckets"].is_a?(Array)
          node["buckets"]
        else
          []
        end
      end

    # Helper to build ancestry-based tree with counts
    build_ancestry_tree =
      lambda do |model_class, counts_map|
        arranged = model_class.arrange(order: :name)
        mapper = nil
        mapper =
          lambda do |tree_hash|
            tree_hash.map do |record, children_hash|
              node = { name: record.name, eid: record.eid, count: counts_map[record.id] || 0 }
              children = mapper.call(children_hash) if children_hash.present?
              node[:children] = children || []
              node
            end
          end
        mapper.call(arranged)
      end

    # Propagate children's counts to parent nodes. If any child has a non-zero count,
    # set the parent's count to the sum of its children's counts.
    propagate_counts_upwards =
      lambda do |nodes|
        nodes.each do |node|
          kids = node[:children] || []
          propagate_counts_upwards.call(kids) if kids.any?
          next unless kids.any?

          child_counts = kids.map { |c| c[:count].to_i }
          node[:count] = child_counts.sum if child_counts.any? { |c| c&.positive? }
        end
        nodes
      end

    category_buckets = extract_buckets.call(aggs, :categories)
    sd_buckets = extract_buckets.call(aggs, :scientific_domains)

    # Map bucket keys (IDs) to counts
    category_counts = category_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }
    sd_counts = sd_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }

    # Build hierarchical trees merged with counts (include zero-count entries)
    categories = propagate_counts_upwards.call(build_ancestry_tree.call(Category, category_counts))
    scientific_domains = propagate_counts_upwards.call(build_ancestry_tree.call(ScientificDomain, sd_counts))

    # Providers (eid should be pid)
    provider_buckets = extract_buckets.call(aggs, :providers)
    provider_counts = provider_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }
    prov_records = Provider.pluck(:id, :name, :pid)
    providers = prov_records.map { |id, name, pid| { name: name, eid: pid, count: provider_counts[id] || 0 } }
    providers.sort_by! { |h| [-h[:count], h[:name].to_s.downcase] }

    # Target users come from dedicated_for field in ES
    tu_buckets = extract_buckets.call(aggs, :dedicated_for)
    tu_counts = tu_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }
    tu_records = TargetUser.pluck(:id, :name, :eid)
    target_users = tu_records.map { |id, name, eid| { name: name, eid: eid, count: tu_counts[id] || 0 } }
    target_users.sort_by! { |h| [-h[:count], h[:name].to_s.downcase] }

    # Platforms
    platform_buckets = extract_buckets.call(aggs, :platforms)
    platform_counts = platform_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }
    plat_records = Platform.pluck(:id, :name, :eid)
    platforms = plat_records.map { |id, name, eid| { name: name, eid: eid, count: platform_counts[id] || 0 } }
    platforms.sort_by! { |h| [-h[:count], h[:name].to_s.downcase] }

    # Research activities
    ra_buckets = extract_buckets.call(aggs, :research_activities)
    ra_counts = ra_buckets.to_h { |b| [b["key"].to_i, b["doc_count"].to_i] }
    ra_records = Vocabulary::MarketplaceLocation.pluck(:id, :name, :eid)
    research_activities = ra_records.map { |id, name, eid| { name: name, eid: eid, count: ra_counts[id] || 0 } }
    research_activities.sort_by! { |h| [-h[:count], h[:name].to_s.downcase] }

    # Simple filters: rating and order_type
    rating_buckets = extract_buckets.call(aggs, :rating)
    order_type_buckets = extract_buckets.call(aggs, :order_type)

    # Use mappings similar to FederatedSearchHelper::SIMPLE_FILTERS
    rating_value_mapping = {
      "5" => "5 stars",
      "4" => "4+ stars",
      "3" => "3+ stars",
      "2" => "2+ stars",
      "1" => "1+ stars"
    }
    order_type_value_mapping = {
      "open_access" => "Open Access",
      "fully_open_access" => "Fully Open Access",
      "order_required" => "Order Required",
      "other" => "Other"
    }

    # Build complete lists for simple filters, include zero-counts
    rating_counts = rating_buckets.to_h { |b| [b["key"].to_s, b["doc_count"].to_i] }
    ratings =
      rating_value_mapping.keys.map do |key|
        { name: rating_value_mapping[key] || key.to_s.humanize, eid: key.to_s, count: rating_counts[key] || 0 }
      end

    order_type_counts = order_type_buckets.to_h { |b| [b["key"].to_s, b["doc_count"].to_i] }
    order_types =
      order_type_value_mapping.keys.map do |key|
        { name: order_type_value_mapping[key] || key.to_s.humanize, eid: key.to_s, count: order_type_counts[key] || 0 }
      end

    {
      categories: categories,
      scientific_domains: scientific_domains,
      providers: providers,
      target_users: target_users,
      platforms: platforms,
      research_activities: research_activities,
      rating: ratings,
      order_type: order_types
    }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
