# frozen_string_literal: true

require "image_processing/vips"
require "marcel/mime_type"

module ImageHelper
  PERMITTED_EXT_MESSAGE =
    "format you're trying to attach is not supported.
           Supported formats: png, gif, jpg, jpeg, pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon."
  DEFAULT_LOGO_PATH = "service_logo.svg"
  DEFAULT_PROVIDER_LOGO_PATH = "provider_logo.svg"
  DEFAULT_CATALOGUE_LOGO_PATH = "catalogue_logo.svg"

  def self.to_temp_file(logo, ext)
    tmp_logo = Tempfile.new(["logo_temp", ext])
    tmp_logo.binmode
    tmp_logo.write logo.read
    tmp_logo.close
    tmp_logo.path
  end

  def self.to_base64(path)
    content_type = Marcel::MimeType.for(Pathname.new(path))
    File.open(path, "rb") { |img| "data:" + content_type + ";base64," + Base64.strict_encode64(img.read) }
  rescue StandardError
    "Not recognized or not permitted file type"
  end

  def self.binary_to_blob_stream(file_path)
    File.open(file_path, "rb") do |binary_img|
      encoded_image = Base64.strict_encode64(binary_img.read)
      decoded_image = Base64.decode64(encoded_image)
      blob = Vips::Image.new_from_buffer(decoded_image, "")

      logo = StringIO.new
      logo.write(blob)
      logo
    end
  end

  def self.base_64_to_blob_stream(base64)
    extension = ImageHelper.base_64_extension(base64)
    decoded_image = Base64.decode64(base64[(base64.index("base64,") + "base64,".size)..])
    blob = Vips::Image.new_from_buffer(decoded_image, "")
    logo = StringIO.new
    logo.write(blob)
    logo.seek(0)

    [logo, extension]
  end

  def self.image_valid?(url)
    Timeout.timeout(10) do
      logo = URI.parse(url).open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      extension = Rack::Mime::MIME_TYPES.invert[logo.content_type]
      return false unless ImageHelper.image_ext_permitted?(extension)

      true
    rescue StandardError
      return false
    end
  rescue Timeout::Error
    false
  end

  def self.image_ext_permitted?(extension)
    %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
  end

  def self.base_64_extension(base64)
    metadata = base64.split("base64,")[0]
    extension = "." + metadata[%r{image/[a-zA-Z]+}].gsub!(%r{image/}, "")
    unless ImageHelper.image_ext_permitted?(extension)
      msg = "Conversion of binary image to base64 can't be done on file with extension #{extension}"
      Sentry.capture_message(msg)
      raise msg
    end

    extension
  end

  def self.get_file_extension(file_path)
    file_name = file_path.split("/")[-1]
    extension = "." + file_name.split(".")[-1]
    unless ImageHelper.image_ext_permitted?(extension)
      msg = "Conversion of binary image to base64 can't be done on file with extension #{extension}"
      Sentry.capture_message(msg)
      raise msg
    end

    extension
  end

  def self.to_json(logo)
    unless logo.present? && logo.original_filename.present? && logo.path.present? && logo.content_type.present?
      return nil
    end

    { "filename" => logo.original_filename, "base64" => ImageHelper.to_base64(logo.path), "type" => logo.content_type }
  end
end
