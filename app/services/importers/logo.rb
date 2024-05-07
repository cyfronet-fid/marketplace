# frozen_string_literal: true

require "image_processing/mini_magick"
require "timeout"

class Importers::Logo < ApplicationService
  class LogoNotAvailableError < StandardError
  end

  def initialize(object, image_url)
    super()
    @object = object
    @image_url = image_url
  end

  def call
    Timeout.timeout(10) do
      logo = URI.parse(@image_url).open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      logo_content_type = logo.content_type
      extension = Rack::Mime::MIME_TYPES.invert[logo_content_type]
      filename = @object.pid.present? ? @object.pid : to_slug(@object.name)
      unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
        logo = convert_to_png(logo, extension)
        logo_content_type = "image/png"
        extension = ".png"
      end

      if logo.present? && logo_content_type.start_with?("image")
        @object.logo.attach(io: logo, filename: filename + extension, content_type: logo_content_type)
      end
    rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, LogoNotAvailableError, SocketError => e
      log "ERROR - there was a problem processing image for #{@object.name} #{@image_url}: #{e}"
    rescue StandardError => e
      log "ERROR - there was a unexpected problem processing image for #{@object.name} #{@image_url}: #{e}"
    end
  rescue Timeout::Error => e
    log "ERROR - there was a problem with image loading from #{@image_url}: #{e}"
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
  end

  def to_slug(ret)
    ret
      .downcase
      .strip
      .gsub(/['`]/, "")
      .gsub(/\s*@\s*/, " at ")
      .gsub(/\s*&\s*/, " and ")
      .gsub(/\s*[^A-Za-z0-9.-]\s*/, "-")
      .gsub(/_+/, "_")
      .gsub(/\A[_.]+|[_.]+\z/, "")
      .gsub(/-+/, "-")
      .gsub(/-$/, "")
  end

  def log(msg)
    Rails.logger.error msg
  end
end
