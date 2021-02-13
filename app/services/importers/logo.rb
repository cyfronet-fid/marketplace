# frozen_string_literal: true

require "mini_magick"

class Importers::Logo
  class LogoNotAvailableError < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  def initialize(object, image_url)
    @object = object
    @image_url = image_url
  end

  def call
    logo = open(@image_url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    logo_content_type = logo.content_type
    extension = Rack::Mime::MIME_TYPES.invert[logo_content_type]

    unless [".jpg", ".jpeg", ".pjpeg", ".png", ".gif", ".tiff"].include?(extension)
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
      logo_content_type = "image/png"
    end
    if !logo.blank? && logo_content_type.start_with?("image")
      @object.logo.attach(io: logo, filename: @object.pid, content_type: logo_content_type)
    end
  rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, LogoNotAvailableError, SocketError => e
    Rails.logger.warn "ERROR - there was a problem processing image for #{@object.pid} #{@image_url}: #{e}"
  rescue => e
    Rails.logger.warn "ERROR - there was a unexpected problem processing image for #{@object.pid} #{@image_url}: #{e}"
  end
end
