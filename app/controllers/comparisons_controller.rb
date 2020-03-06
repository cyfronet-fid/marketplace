# frozen_string_literal: true

class ComparisonsController < ApplicationController
  def show
    @compare_services = Service.where(slug: session[:comparison])
    redirect_to_services_path
  end

  def destroy
    session[:comparison] = []
    respond_to do |format|
      format.html { redirect_to services_path }
      format.js { render_json }
    end
  end

  private
    def redirect_to_services_path
      if @compare_services.blank?
        if params[:fromc]
          category = Category.find_by(slug: params[:fromc])
          redirect_to category_services_path(category)
        else
          redirect_to services_path
        end
      end
    end

    def render_json
      render json: { data: session[:comparison], html: render_bottom_bar }
    end

    def render_bottom_bar
      render_to_string(partial: "comparisons/service", collection: @compare_services, formats: [:html])
    end
end
