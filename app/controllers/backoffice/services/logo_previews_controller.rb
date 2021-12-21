# frozen_string_literal: true

require "image_processing/mini_magick"

class Backoffice::Services::LogoPreviewsController < Backoffice::ApplicationController
  include ImageHelper

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
    logo = get_session_logo
    has_service_logo = @service&.logo && @service.logo.attached? && @service.logo.variable?
    if logo.present? && !ImageHelper.image_ext_permitted?(File.extname(logo["filename"]))
      @service.errors.add(:logo, ImageHelper.permitted_ext_message)
      redirect_to ImageHelper.default_logo_path
    elsif logo.present?
      blob, ext = ImageHelper.base_64_to_blob_stream(logo["base64"])
      path = ImageHelper.to_temp_file(blob, ext)
      resized_logo = ImageProcessing::MiniMagick.source(path).resize_to_limit!(180, 120)
      send_file resized_logo.path, type: ext
    elsif has_service_logo
      redirect_to url_for(@service.logo.variant(resize: "180x120"))
    else
      redirect_to ImageHelper.default_logo_path
    end
  end

  def get_session_logo
    preview_session = session["service-#{@service&.id}-preview"]
    if preview_session.present? && preview_session["logo"].present? && preview_session["logo"]["base64"].present?
      preview_session["logo"]
    end
  end
end
