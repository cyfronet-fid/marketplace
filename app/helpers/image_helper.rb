# frozen_string_literal: true

require "mini_magick"

module ImageHelper
  def self.binary_to_blob_stream(file_path)
    File.open(file_path, "rb") do |binaryImg|
      extension = ImageHelper.get_file_extension(file_path)
      encoded_image = Base64.strict_encode64(binaryImg.read)
      decoded_image = Base64.decode64(encoded_image)
      blob = MiniMagick::Image.read(decoded_image, extension).to_blob
      logo = StringIO.new
      logo.write(blob)
      logo.seek(0)

      [logo, extension]
    end
  end

  def self.base_64_to_blob_stream(base_64)
    extension = ImageHelper.get_base_64_extension(base_64)
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
        logo_content_type = logo.content_type
        extension = Rack::Mime::MIME_TYPES.invert[logo_content_type]
        unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
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

  private
    def self.get_file_extension(file_path)
      file_name = file_path.split("/")[-1]
      extension = "." + file_name.split(".")[-1]
      unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
        msg = "Conversion of binary image to base64 can't be done on file with extension #{extension}"
        Raven.capture_message(msg)
        raise msg
      end

      extension
    end

    def self.get_base_64_extension(base_64)
      metadata = base_64.split("base64,")[0]
      extension = "." + metadata[/image\/[a-zA-Z]+/].gsub!(/image\//, "")
      unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
        msg = "Conversion of binary image to base64 can't be done on file with extension #{extension}"
        Raven.capture_message(msg)
        raise msg
      end

      extension
    end
end
