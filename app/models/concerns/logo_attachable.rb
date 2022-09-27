# frozen_string_literal: true

module LogoAttachable
  include ImageHelper

  def logo_variable
    errors.add(:logo, ImageHelper::PERMITTED_EXT_MESSAGE) if logo.present? && !logo.variable?
  end

  def update_logo!(logo)
    blob, ext = ImageHelper.base_64_to_blob_stream(logo["base64"])
    path = ImageHelper.to_temp_file(blob, ext)
    self.logo.attach(io: File.open(path), filename: logo["filename"])
  end
end
