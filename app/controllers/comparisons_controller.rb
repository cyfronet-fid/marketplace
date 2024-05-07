# frozen_string_literal: true

class ComparisonsController < ApplicationController
  include Service::Comparison
  before_action :load_query_params_from_session

  def show
    @services = Service.where(slug: session[:comparison])
    if @services.blank?
      if params[:fromc]
        category = Category.find_by(slug: params[:fromc])
        redirect_to category_services_path(category, params: @query_params)
      else
        redirect_to services_path(params: @query_params), allow_other_host: true
      end
    end
  end

  def destroy
    session[:comparison] = []
    respond_to do |format|
      format.html { redirect_to services_path(@query_params) }
      format.turbo_stream
    end
  end

  private

  def render_json
    render json: { data: @services&.map(&:slug), html: bottom_bar }
  end

  def bottom_bar
    render_to_string(partial: "comparisons/service", collection: @services, formats: [:html])
  end
end
