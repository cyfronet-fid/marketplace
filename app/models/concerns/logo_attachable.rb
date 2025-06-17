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

  def set_default_logo
    assets_path = File.join(File.dirname(__FILE__), "../../assets/images")
    default_logo_name = "eosc-img.png"
    extension = ".png"
    io = ImageHelper.binary_to_blob_stream(assets_path + "/" + default_logo_name)
    logo.attach(io: io, filename: SecureRandom.uuid + extension, content_type: "image/#{extension.delete(".", "")}")
  end

  def convert_to_png(logo)
    img = Vips::Image.new_from_buffer(logo.read, "")
    logo.rewind

    img = Vips::Image.thumbnail(img, 800, height: 800, size: :down)
    img.write_to_buffer(".png")

    logo = StringIO.new
    logo.write(img)
    logo.rewind
    logo
  end
end
