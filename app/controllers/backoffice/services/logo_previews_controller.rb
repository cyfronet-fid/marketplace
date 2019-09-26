# frozen_string_literal: true

class Backoffice::Services::LogoPreviewsController < Backoffice::ApplicationController
  def show
    if params[:service_id] == "new"
      authorize(Service, :new?)
    else
      @service = Service.friendly.find(params[:service_id])
      authorize(@service)
    end

    show_logo_preview
  end

  private

    def show_logo_preview
      puts "service id: #{params[:service_id]}"
      logo = logo_from_session

      if logo && File.exist?(logo["path"])
        send_file logo["path"], type: logo["type"]
      elsif @service&.logo
        redirect_to url_for(@service.logo.variant(resize: "180x120"))
      else
        raise ActionController::RoutingError.new("Not Found")
      end
    end

    def preview_session_key
      "service-#{@service&.id}-preview"
    end

    def logo_from_session
      preview = session[preview_session_key]
      preview["logo"] if preview
    end
end
