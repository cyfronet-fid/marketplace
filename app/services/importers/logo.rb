# frozen_string_literal: true

require "mini_magick"
require "timeout"

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
    Timeout.timeout(10) {
      begin
        logo = open(@image_url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
        logo_content_type = logo.content_type
        extension = Rack::Mime::MIME_TYPES.invert[logo_content_type]
        unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
          logo_content_type = "image/png"
          extension = ".png"
          logo = convert_to_png(logo, extension)
        end

        if !logo.blank? && logo_content_type.start_with?("image")
          @object.logo.attach(io: logo, filename: @object.pid + extension, content_type: logo_content_type)
        end
      rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, LogoNotAvailableError, SocketError => e
        Rails.logger.warn "ERROR - there was a problem processing image for #{filename} #{@image_url}: #{e}"
      rescue => e
        Rails.logger.warn "ERROR - there was a unexpected problem processing image for #{@object.pid} #{@image_url}: #{e}"
      end
    }
  rescue Timeout::Error => e
    Rails.logger.warn "ERROR - there was a problem with image loading from #{@image_url}: #{e}"
  end

  private
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
    rescue ThreadError, IOError => e
      Rails.logger.warn "ERROR - there was a problem converting file wit ext #{extension} from #{@image_url}: #{e}"
    ensure
      nil
    end
end
