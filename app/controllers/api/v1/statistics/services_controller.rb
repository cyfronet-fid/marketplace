# frozen_string_literal: true

# The Statistics API (ADR-0007 D33–D42): the Service statistics of this Node,
# by PID, for the Resource Catalogue. ::Statistics::ServiceStatistics builds
# the figures; this controller handles paging, filters and errors.
class Api::V1::Statistics::ServicesController < Api::V1::ApplicationController
  before_action :authorize_statistics
  before_action :validate_page_params, only: :index

  def index
    # One Service past the page tells whether another page follows.
    services = visible_services.where(id: (@page_params.from_id + 1)..)
    services = services.where(pid: @page_params.pids) if @page_params.pids
    services = services.order(:id).limit(@page_params.limit + 1).to_a
    page = services.first(@page_params.limit)

    render json: {
      statistics: ::Statistics::ServiceStatistics.call(page),
      next_from_id: (page.last.id if services.size > @page_params.limit)
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

  def validate_page_params
    @page_params = ::Statistics::PageParams.from_query(params)
    return if @page_params.valid?

    render json: { error: @page_params.errors.map(&:message).join("; ") }, status: :bad_request
  end

  def visible_services
    policy_scope(Service, policy_scope_class: Api::V1::StatisticsPolicy::Scope)
  end
end
