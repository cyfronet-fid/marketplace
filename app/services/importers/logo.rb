# frozen_string_literal: true

require "image_processing/vips"
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
      filename = @object.abbreviation.present? ? "#{@object.id}-#{@object.abbreviation}" : to_slug(@object.name)
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
    option = extension == ".svg" ? "scale=2" : ""
    img = Vips::Image.new_from_buffer(logo.read, option)
    png_buffer = img.write_to_buffer(".png")

    io = StringIO.new(png_buffer)
    io.set_encoding("binary")
    io.rewind
    io
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
