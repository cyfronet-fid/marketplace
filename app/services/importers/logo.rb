# frozen_string_literal: true

require "image_processing/vips"
require "timeout"

class Importers::Logo < ApplicationService
  PNG_CONTENT_TYPE = "image/png"
  SVG_CONTENT_TYPE = "image/svg+xml"
  TTL = 10

  def initialize(url)
    super()

    @url = url
  end

  def call
    return if @url.blank?

    Timeout.timeout(TTL) do
      file = fetch_file_from_url

      return if file.blank?
      return unless image_content_type?(file)

      { io: convert_to_png(file), filename: "#{SecureRandom.uuid}.png", content_type: PNG_CONTENT_TYPE }
    end
  rescue Vips::Error => e
    Rails.logger.error "Error on processing logo from #{@url}: #{e.message}"

    nil
  end

  private

  def fetch_file_from_url
    URI.parse(@url).open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  rescue URI::InvalidURIError, OpenURI::HTTPError, Errno::EHOSTUNREACH, SocketError, Timeout::Error => e
    Rails.logger.error "Error on fetching logo from #{@url}: #{e.message}"

    nil
  end

  def image_content_type?(file)
    file.content_type.to_s.start_with?("image/")
  end

  def convert_to_png(file)
    option = file.content_type == SVG_CONTENT_TYPE ? "scale=2" : ""
    image = Vips::Image.new_from_buffer(file.read, option)

    io = StringIO.new(image.write_to_buffer(".png"))
    io.set_encoding("binary")
    io.rewind
    io
  end
end
