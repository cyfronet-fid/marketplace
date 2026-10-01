# frozen_string_literal: true

class Api::V1::Catalogue::ServicesController < ActionController::API
  include Pundit::Authorization

  def index
    keyword = params[:keyword].to_s.strip
    from = to_non_negative_integer(params[:from], 0)
    quantity = to_positive_integer(params[:quantity], 10)
    order =
      if %w[asc desc].include?(params[:order].to_s.downcase)
        params[:order].to_s.downcase
      else
        params[:keyword].present? ? "desc" : "asc"
      end

    scope = policy_scope(Service)

    total = 0
    services = []

    if keyword.present? && Service.respond_to?(:search)
      # Use Searchkick if available
      search_results =
        Service.search(
          keyword,
          fields: %i[
            name
            tagline
            abbreviation
            description
            offer_names
            resource_organisation_name
            provider_names
            node_names
          ],
          where: {
            status: %w[published suspended]
          },
          order: {
            sort_name: order.to_sym
          },
          offset: from,
          limit: quantity
        )
      total = search_results.total_count
      services = search_results.results
    else
      total = scope.count
      services = scope.order(name: order).offset(from).limit(quantity).to_a
    end

    render json: {
      total: total,
      from: from,
      to: from + quantity,
      results: services.map { |s| { id: s.pid, service: Catalogue::ServiceSerializer.new(s).as_json } }
    }
  end

  private

  def to_non_negative_integer(value, default)
    int =
      begin
        Integer(value)
      rescue StandardError
        default
      end
    int = default if int.nil?
    int.negative? ? default : int
  end

  def to_positive_integer(value, default)
    int =
      begin
        Integer(value)
      rescue StandardError
        default
      end
    int = default if int.nil? || int <= 0
    int
  end

  def policy_scope(scope)
    super([:api, :v1, :catalogue, scope])
  end

  def authorize(record, query = nil)
    super([:api, :v1, :catalogue, record], query)
  end
end
