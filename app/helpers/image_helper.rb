# frozen_string_literal: true

require "mini_magick"

module ImageHelper
  @@PERMITTED_EXT_MESSAGE = "format you're trying to attach is not supported.
           Supported formats: png, gif, jpg, jpeg, pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon."
  @@DEFAULT_LOGO_PATH = Webpacker.manifest.lookup("media/images/eosc-img.png")

  def self.default_logo_path
    @@DEFAULT_LOGO_PATH
  end

  def self.permitted_ext_message
    @@PERMITTED_EXT_MESSAGE
  end

  def self.to_temp_file(logo, ext)
    tmp_logo = Tempfile.new(["logo_temp", ext])
    tmp_logo.binmode
    tmp_logo.write logo.read
    tmp_logo.close
    tmp_logo.path
  end

  def self.to_base_64(path)
    content_type = MIME::Types.type_for(path).first.content_type
    File.open(path, "rb") do |img|
      "data:" + content_type + ";base64," + Base64.strict_encode64(img.read)
    end
  end

  def self.binary_to_blob_stream(file_path)
    File.open(file_path, "rb") do |binaryImg|
      extension = ImageHelper.get_file_extension(file_path)
      encoded_image = Base64.strict_encode64(binaryImg.read)
      decoded_image = Base64.decode64(encoded_image)
      blob = MiniMagick::Image.read(decoded_image, extension).to_blob
      logo = StringIO.new
      logo.write(blob)
      logo.seek(0)
      logo
    end
  end

  def self.base_64_to_blob_stream(base_64)
    extension = ImageHelper.base_64_extension(base_64)
    decoded_image = Base64.decode64(base_64[(base_64.index("base64,") + "base64,".size)..-1])
    blob = MiniMagick::Image.read(decoded_image, extension).to_blob
    logo = StringIO.new
    logo.write(blob)
    logo.seek(0)

    [logo, extension]
  end

  def self.image_valid?(url)
    Timeout.timeout(10) {
      begin
        logo = open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
        extension = Rack::Mime::MIME_TYPES.invert[logo.content_type]
        unless ImageHelper.image_ext_permitted?(extension)
          return false
        end

        true
        rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, LogoNotAvailableError, SocketError
          return false
        rescue Exception
          return false
      end
    }
  rescue Timeout::Error
    false
  end

  def self.image_ext_permitted?(extension)
    %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
  end

  def self.base_64_extension(base_64)
    metadata = base_64.split("base64,")[0]
    extension = "." + metadata[/image\/[a-zA-Z]+/].gsub!(/image\//, "")
    unless ImageHelper.image_ext_permitted?(extension)
      msg = "Conversion of binary image to base64 can't be done on file with extension #{extension}"
      Sentry.capture_message(msg)
      raise msg
    end

    extension
  end

  private
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
end
