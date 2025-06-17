# frozen_string_literal: true

require "image_processing/vips"

class Backoffice::Services::LogoPreviewsController < Backoffice::ApplicationController
  include ImageHelper
  include Backoffice::ServicesSessionHelper

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
    logo = session_logo
    has_service_logo = @service&.logo && @service.logo.attached? && @service.logo.variable?
    if logo.present? && !ImageHelper.image_ext_permitted?(File.extname(logo["filename"]))
      @service.errors.add(:logo, ImageHelper::PERMITTED_EXT_MESSAGE)
      redirect_to ActionController::Base.helpers.asset_url(ImageHelper::DEFAULT_LOGO_PATH)
    elsif logo.present?
      blob, ext = ImageHelper.base_64_to_blob_stream(logo["base64"])
      path = ImageHelper.to_temp_file(blob, ext)
      resized_logo = Vips::Image.new_from_file(path).resize_to_limit!(180, 120)
      send_file resized_logo.path, type: ext
    elsif has_service_logo
      redirect_to url_for(@service.logo.variant(resize_to_limit: [180, 120]))
    else
      redirect_to ActionController::Base.helpers.asset_url(ImageHelper::DEFAULT_LOGO_PATH)
    end
  end

  def session_logo
    preview_session = session[session_key]
    if preview_session.present? && preview_session["logo"].present? && preview_session["logo"]["base64"].present?
      preview_session["logo"]
    end
  end
end
