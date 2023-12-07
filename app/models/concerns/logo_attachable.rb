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

  def convert_to_png(logo, extension)
    img = MiniMagick::Image.read(logo, extension)
    img.format "png" do |convert|
      convert.args.unshift "800x800"
      convert.args.unshift "-resize"
      convert.args.unshift "1200"
      convert.args.unshift "-density"
      convert.args.unshift "none"
      convert.args.unshift "-background"
    end
    logo = StringIO.new
    logo.write(img.to_blob)
    logo.seek(0)
    logo
  end
end
