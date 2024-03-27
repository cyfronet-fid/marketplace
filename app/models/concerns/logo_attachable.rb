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
