# frozen_string_literal: true

class Projects::ResearchProductsController < Projects::ServicesController
  include Project::Authorize

  before_action :find_research_product

  def show
  end

  def destroy
    @project_research_product =
      ProjectResearchProduct.find_by(project_id: @project.id, research_product_id: @research_product.id)
    if @project_research_product.destroy
      flash[:notice] = _("Research Product removed successfully")
      redirect_to project_services_path(@project)
    else
      render :show, status: :bad_request
    end
  end

  def find_research_product
    @research_product = ResearchProduct.friendly.find(params[:id])
  end
end
