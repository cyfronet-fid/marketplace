# frozen_string_literal: true

class Comparisons::ServicesController < ComparisonsController
  def create
    new_service_slug = params.fetch(:comparison)
    current_slugs = session[:comparison].blank? ? [] : session[:comparison]
    if current_slugs.include?(new_service_slug)
      current_slugs.delete(new_service_slug)
    else
      current_slugs << new_service_slug
    end
    session[:comparison] = current_slugs
    @services = Service.where(slug: session[:comparison])
    respond_to { |format| format.json { render_json } }
  end

  def destroy
    session[:comparison].delete(params[:slug])
    redirect_to comparisons_path(params[:fromc].present? ? { fromc: params[:fromc] } : nil)
  end
end
