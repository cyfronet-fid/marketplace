# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
    include Service::Categorable
    before_action only: :index do
      @filters = visible_filters
      @active_filters = active_filters
      store_query_params
    end
  end

  def search(scope, filters = all_filters, additionals_size: 0)
    services =
      Service.search(
        query,
        **common_params.merge(
          where: filter_constr(filters, scope_constr(scope, category_constr)),
          page: params[:page],
          per_page: "#{per_page(additionals_size)}",
          order: ordering,
          highlight: {
            tag: "<mark>"
          },
          scope_results: ->(r) do
            r.includes(:scientific_domains, :providers, :target_users, :offers).with_attached_logo
          end
        )
      )

    offers =
      Offer.search(
        query,
        where: {
          service_id: services.results.map(&:id)
        },
        load: false,
        fields: [:offer_name],
        operator: :or,
        match: :word_middle,
        highlight: {
          tag: "<mark>"
        }
      )
    [services, service_offers(services, offers)]
  end

  def search_for_filters(scope, filters, current_filter)
    filters -= [current_filter]
    Service.search(
      query,
      **common_params.merge(
        where: filter_constr(filters, scope_constr(scope, category_constr)),
        aggs: [current_filter.index],
        load: false
      )
    )
  end

  def search_for_categories(scope, filters)
    Service.search(
      query,
      **common_params.merge(where: filter_constr(filters, scope_constr(scope)), aggs: [:categories], load: false)
    )
  end

  def filter_counters(scope, filters, current_filter)
    {}.tap do |hash|
      unless current_filter.index.blank?
        services = search_for_filters(scope, filters, current_filter)
        services.aggregations[current_filter.index][current_filter.index]["buckets"].each_with_object(hash) do |e, h|
          h[e["key"]] = e["doc_count"]
        end
      end
    end
  end

  private

  def service_offers(_services, offers)
    offers.with_highlights.group_by { |o, _| o.service_id }.to_h
  end

  def query_present?
    params[:q].present?
  end

  def query
    query_present? ? params[:q] : "*"
  end

  def common_params
    {
      fields: %w[name^7 tagline^3 description offer_names provider_names resource_organisation_name],
      operator: "or",
      match: :word_middle
    }
  end

  def scope_constr(scope, constr = {})
    constr.tap { |c| c[:id] = scope.ids.uniq }
  end

  def category_constr(constr = {})
    constr.tap { |c| c[:categories] = category.descendant_ids + [category.id] unless category.nil? }
  end

  def filter_constr(filters, constr = {})
    filters.reduce(constr) { |c, f| c.merge(f.constraint) }
  end

  def highlights(from_search)
    result = from_search.try(:with_highlights) if (params[:q]&.size || 0) > 2
    {} if result.blank?
    result.to_h.transform_keys(&:id)
  end

  def visible_filters
    all_filters.select(&:visible?)
  end

  def all_filters
    @all_filters ||=
      filter_classes
        .map { |f| f.new(params: params) }
        .tap { |all| all.each { |f| f.counters = filter_counters(scope, all, f) } }
  end

  def active_filters
    @active_filters ||= all_filters.flat_map(&:active_filters)
  end

  def store_query_params
    session[:query] = {}
    @filters.each do |filter|
      session[:query][filter.field_name] = params[filter.field_name] unless params[filter.field_name].blank?
      session[:query]["#{filter.field_name}-all"] = params["#{filter.field_name}-all"] unless params[
        "#{filter.field_name}-all"
      ].blank?
    end
    session[:query][:q] = params[:q] unless params[:q].blank?
    session[:query][:sort] = params[:sort] unless params[:sort].blank?
    session[:query][:per_page] = params[:per_page] unless params[:per_page].blank?
    session[:query][:page] = params[:page] unless params[:page].blank?
  end

  def filter_classes
    url_path = URI.parse(request.path).path
    backoffice = url_path.start_with?("/backoffice")
    [
      Filter::ScientificDomain,
      backoffice ? Filter::BackofficeProvider : Filter::Provider,
      Filter::TargetUser,
      Filter::Platform,
      Filter::Rating,
      Filter::OrderType,
      Filter::Location,
      Filter::Tag
    ]
  end
end
