# frozen_string_literal: true

class ComparisonsController < ApplicationController
  def show
    @services = Service.where(slug: session[:comparison])
    if @services.blank?
      if params[:fromc]
        category = Category.find_by(slug: params[:fromc])
        redirect_to category_services_path(category)
      else
        redirect_to services_path
      end
    end
  end

  def destroy
    session[:comparison] = []
    respond_to do |format|
      format.html { redirect_to services_path }
      format.js { render_json }
    end
  end

  private
    def render_json
      render json: { data: session[:comparison], html: bottom_bar }
    end

    def bottom_bar
      render_to_string(partial: "comparisons/service", collection: @services, formats: [:html])
    end
end
