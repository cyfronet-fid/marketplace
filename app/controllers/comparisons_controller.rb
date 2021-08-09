# frozen_string_literal: true

class ComparisonsController < ApplicationController
  include Service::Comparison
  before_action :query_params, only: [:show, :destroy]

  def show
    @services = Service.where(slug: session[:comparison])
    if @services.blank?
      if params[:fromc]
        category = Category.find_by(slug: params[:fromc])
        redirect_to category_services_path(category, params: @query_params)
      else
        redirect_to services_path(params: @query_params)
      end
    end
  end

  def destroy
    session[:comparison] = []
    respond_to do |format|
      format.html { redirect_to services_path(@query_params) }
      format.js { render_json }
    end
  end

  private
    def query_params
      @query_params = session[:query] || {}
    end

    def render_json
      render json: { data: @services&.map(&:slug), html: bottom_bar }
    end

    def bottom_bar
      render_to_string(partial: "comparisons/service", collection: @services, formats: [:html])
    end
end
