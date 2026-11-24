# frozen_string_literal: true

# The Statistics API (ADR-0008 D33–D42): the Service statistics of this Node,
# by PID, for the Resource Catalogue. ::Statistics::ServiceStatistics builds
# the figures; this controller handles paging, filters and errors.
class Api::V1::Statistics::ServicesController < Api::V1::ApplicationController
  DEFAULT_LIMIT = 100
  MAX_LIMIT = 1000
  MAX_PIDS = 100

  before_action :authorize_statistics
  before_action :validate_from_id, :validate_page_limit, :validate_pids, only: :index

  def index
    # One Service past the page tells whether another page follows.
    services = visible_services.where(id: (@from_id + 1)..)
    services = services.where(pid: @pids) if @pids
    services = services.order(:id).limit(@limit + 1).to_a
    page = services.first(@limit)

    render json: {
      statistics: ::Statistics::ServiceStatistics.call(page),
      next_from_id: (page.last.id if services.size > @limit)
    }
  end

  # Matches the pid column only, without FriendlyId: the API knows Services by PID.
  def show
    service = visible_services.find_by(pid: params[:id])
    return render json: { error: "Service not found" }, status: :not_found if service.nil?

    render json: ::Statistics::ServiceStatistics.call([service]).sole
  end

  private

  def authorize_statistics
    authorize Service, policy_class: Api::V1::StatisticsPolicy
  end

  # validate_limit has another default and no maximum.
  def validate_page_limit
    @limit = params[:limit].present? ? params[:limit].to_i : DEFAULT_LIMIT
    return if @limit.between?(1, MAX_LIMIT)

    render json: { error: "'limit' must be an integer from 1 to #{MAX_LIMIT}" }, status: :bad_request
  end

  # pid[]=…&pid[]=…, which narrows the page to those PIDs.
  def validate_pids
    @pids = params[:pid]
    return if @pids.nil?

    if !@pids.is_a?(Array) || !@pids.all?(String)
      render json: { error: "'pid' must be a list of PIDs: pid[]=…&pid[]=…" }, status: :bad_request
    elsif @pids.size > MAX_PIDS
      render json: { error: "'pid' must hold at most #{MAX_PIDS} PIDs" }, status: :bad_request
    end
  end

  def visible_services
    policy_scope(Service, policy_scope_class: Api::V1::StatisticsPolicy::Scope)
  end
end
