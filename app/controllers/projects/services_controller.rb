# frozen_string_literal: true

class Projects::ServicesController < ApplicationController
  include Project::Authorize

  before_action :load_projects

  def index
    @project_items = @project.project_items.roots.includes(offer: :orderable, bundle: { offers: :orderable })
    @research_products = @project.research_products
    @order_required_items = @project_items.where(order_type: "order_required")
    @open_access_items = @project_items.where(order_type: %w[open_access fully_open_access])
    @other_items = @project_items.where(order_type: "other")
    @recommended_offers = sample_recommended_offers
  end

  def show
    # Handle both Service and DeployableService offers
    @project_item = @project.project_items.joins(:offer, project: :user).find_by!(iid: params[:id])

    authorize(@project_item)
  end

  def tour_disabled?
    true
  end

  private

  def load_projects
    @projects = policy_scope(Project).order(:name)
  end

  def sample_recommended_offers
    return unless @project_items.present?

    domains = @project.scientific_domains.presence || @project_items.first.service&.scientific_domains
    return Offer.all.sample(2) if domains.blank?

    domain_ids = domains.map(&:id)

    Offer
      .join_orderable
      .with_published_orderable
      .joins(
        "LEFT JOIN service_scientific_domains ON service_scientific_domains.service_id = services.id " \
          "LEFT JOIN deployable_service_scientific_domains " \
          "ON deployable_service_scientific_domains.deployable_service_id = deployable_services.id"
      )
      .where(
        "service_scientific_domains.scientific_domain_id IN (:ids) " \
          "OR deployable_service_scientific_domains.scientific_domain_id IN (:ids)",
        ids: domain_ids
      )
      .distinct
      .sample(2)
      .presence || Offer.all.sample(2)
  end
end
