# frozen_string_literal: true

class Projects::ServicesController < ApplicationController
  include Project::Authorize

  before_action :load_projects

  def index
    @project_items = @project.project_items.roots
    @research_products = @project.research_products
    @order_required_items = @project_items.where(order_type: "order_required")
    @open_access_items = @project_items.where(order_type: %w[open_access fully_open_access])
    @other_items = @project_items.where(order_type: "other")
    @recommended_offers = sample_recommended_offers
  end

  def show
    @project_item = @project.project_items.joins(offer: :service, project: :user).find_by!(iid: params[:id])

    authorize(@project_item)
  end

  def tour_disabled
    true
  end

  private

  def load_projects
    @projects = policy_scope(Project).order(:name)
  end

  def sample_recommended_offers
    if @project_items.present?
      domains = @project.scientific_domains.presence || @project_items.first.service.scientific_domains

      Offer
        .joins(service: :scientific_domains)
        .where(scientific_domains: { id: domains.map(&:id) })
        .distinct
        .sample(2)
        .presence || Offer.all.sample(2)
    end
  end
end
