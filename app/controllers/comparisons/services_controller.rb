# frozen_string_literal: true

class Comparisons::ServicesController < ComparisonsController
  def create
    new_service_slug = params.fetch(:comparison)
    session[:comparison] = session[:comparison].blank? ? [] : session[:comparison]
    session[:comparison].include?(new_service_slug) ?
        session[:comparison].delete(new_service_slug) : session[:comparison] << new_service_slug
    @services = Service.where(slug: session[:comparison])
    respond_to do |format|
      format.json { render_json }
    end
  end

  def destroy
    session[:comparison].delete(params[:slug])
    redirect_to comparisons_path(params[:fromc].present? ? { fromc: params[:fromc] } : nil)
  end
end
